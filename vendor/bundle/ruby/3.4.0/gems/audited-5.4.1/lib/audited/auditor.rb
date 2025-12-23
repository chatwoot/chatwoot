# frozen_string_literal: true

module Audited
  # Specify this act if you want changes to your model to be saved in an
  # audit table.  This assumes there is an audits table ready.
  #
  #   class User < ActiveRecord::Base
  #     audited
  #   end
  #
  # To store an audit comment set model.audit_comment to your comment before
  # a create, update or destroy operation.
  #
  # See <tt>Audited::Auditor::ClassMethods#audited</tt>
  # for configuration options
  module Auditor # :nodoc:
    extend ActiveSupport::Concern

    CALLBACKS = [:audit_create, :audit_update, :audit_destroy]

    module ClassMethods
      # == Configuration options
      #
      #
      # * +only+ - Only audit the given attributes
      # * +except+ - Excludes fields from being saved in the audit log.
      #   By default, Audited will audit all but these fields:
      #
      #     [self.primary_key, inheritance_column, 'lock_version', 'created_at', 'updated_at']
      #   You can add to those by passing one or an array of fields to skip.
      #
      #     class User < ActiveRecord::Base
      #       audited except: :password
      #     end
      #
      # * +require_comment+ - Ensures that audit_comment is supplied before
      #   any create, update or destroy operation.
      # * +max_audits+ - Limits the number of stored audits.

      # * +redacted+ - Changes to these fields will be logged, but the values
      #   will not. This is useful, for example, if you wish to audit when a
      #   password is changed, without saving the actual password in the log.
      #   To store values as something other than '[REDACTED]', pass an argument
      #   to the redaction_value option.
      #
      #     class User < ActiveRecord::Base
      #       audited redacted: :password, redaction_value: SecureRandom.uuid
      #     end
      #
      # * +if+ - Only audit the model when the given function returns true
      # * +unless+ - Only audit the model when the given function returns false
      #
      #     class User < ActiveRecord::Base
      #       audited :if => :active?
      #
      #       def active?
      #         self.status == 'active'
      #       end
      #     end
      #
      def audited(options = {})
        # don't allow multiple calls
        return if included_modules.include?(Audited::Auditor::AuditedInstanceMethods)

        extend Audited::Auditor::AuditedClassMethods
        include Audited::Auditor::AuditedInstanceMethods

        class_attribute :audit_associated_with, instance_writer: false
        class_attribute :audited_options, instance_writer: false
        attr_accessor :audit_version, :audit_comment

        self.audited_options = options
        normalize_audited_options

        self.audit_associated_with = audited_options[:associated_with]

        if audited_options[:comment_required]
          validate :presence_of_audit_comment
          before_destroy :require_comment if audited_options[:on].include?(:destroy)
        end

        has_many :audits, -> { order(version: :asc) }, as: :auditable, class_name: Audited.audit_class.name, inverse_of: :auditable
        Audited.audit_class.audited_class_names << to_s

        after_create :audit_create if audited_options[:on].include?(:create)
        before_update :audit_update if audited_options[:on].include?(:update)
        after_touch :audit_touch if audited_options[:on].include?(:touch) && ::ActiveRecord::VERSION::MAJOR >= 6
        before_destroy :audit_destroy if audited_options[:on].include?(:destroy)

        # Define and set after_audit and around_audit callbacks. This might be useful if you want
        # to notify a party after the audit has been created or if you want to access the newly-created
        # audit.
        define_callbacks :audit
        set_callback :audit, :after, :after_audit, if: lambda { respond_to?(:after_audit, true) }
        set_callback :audit, :around, :around_audit, if: lambda { respond_to?(:around_audit, true) }

        enable_auditing
      end

      def has_associated_audits
        has_many :associated_audits, as: :associated, class_name: Audited.audit_class.name
      end
    end

    module AuditedInstanceMethods
      REDACTED = "[REDACTED]"

      # Temporarily turns off auditing while saving.
      def save_without_auditing
        without_auditing { save }
      end

      # Executes the block with the auditing callbacks disabled.
      #
      #   @foo.without_auditing do
      #     @foo.save
      #   end
      #
      def without_auditing(&block)
        self.class.without_auditing(&block)
      end

      # Temporarily turns on auditing while saving.
      def save_with_auditing
        with_auditing { save }
      end

      # Executes the block with the auditing callbacks enabled.
      #
      #   @foo.with_auditing do
      #     @foo.save
      #   end
      #
      def with_auditing(&block)
        self.class.with_auditing(&block)
      end

      # Gets an array of the revisions available
      #
      #   user.revisions.each do |revision|
      #     user.name
      #     user.version
      #   end
      #
      def revisions(from_version = 1)
        return [] unless audits.from_version(from_version).exists?

        all_audits = audits.select([:audited_changes, :version, :action]).to_a
        targeted_audits = all_audits.select { |audit| audit.version >= from_version }

        previous_attributes = reconstruct_attributes(all_audits - targeted_audits)

        targeted_audits.map do |audit|
          previous_attributes.merge!(audit.new_attributes)
          revision_with(previous_attributes.merge!(version: audit.version))
        end
      end

      # Get a specific revision specified by the version number, or +:previous+
      # Returns nil for versions greater than revisions count
      def revision(version)
        if version == :previous || audits.last.version >= version
          revision_with Audited.audit_class.reconstruct_attributes(audits_to(version))
        end
      end

      # Find the oldest revision recorded prior to the date/time provided.
      def revision_at(date_or_time)
        audits = self.audits.up_until(date_or_time)
        revision_with Audited.audit_class.reconstruct_attributes(audits) unless audits.empty?
      end

      # List of attributes that are audited.
      def audited_attributes
        audited_attributes = attributes.except(*self.class.non_audited_columns)
        audited_attributes = redact_values(audited_attributes)
        audited_attributes = filter_encrypted_attrs(audited_attributes)
        normalize_enum_changes(audited_attributes)
      end

      # Returns a list combined of record audits and associated audits.
      def own_and_associated_audits
        Audited.audit_class.unscoped.where(auditable: self)
          .or(Audited.audit_class.unscoped.where(associated: self))
          .order(created_at: :desc)
      end

      # Combine multiple audits into one.
      def combine_audits(audits_to_combine)
        combine_target = audits_to_combine.last
        combine_target.audited_changes = audits_to_combine.pluck(:audited_changes).reduce(&:merge)
        combine_target.comment = "#{combine_target.comment}\nThis audit is the result of multiple audits being combined."

        transaction do
          begin
            combine_target.save!
            audits_to_combine.unscope(:limit).where("version < ?", combine_target.version).delete_all
          rescue ActiveRecord::Deadlocked
            # Ignore Deadlocks, if the same record is getting its old audits combined more than once at the same time then
            # both combining operations will be the same. Ignoring this error allows one of the combines to go through successfully.
          end
        end
      end

      protected

      def revision_with(attributes)
        dup.tap do |revision|
          revision.id = id
          revision.send :instance_variable_set, "@new_record", destroyed?
          revision.send :instance_variable_set, "@persisted", !destroyed?
          revision.send :instance_variable_set, "@readonly", false
          revision.send :instance_variable_set, "@destroyed", false
          revision.send :instance_variable_set, "@_destroyed", false
          revision.send :instance_variable_set, "@marked_for_destruction", false
          Audited.audit_class.assign_revision_attributes(revision, attributes)

          # Remove any association proxies so that they will be recreated
          # and reference the correct object for this revision. The only way
          # to determine if an instance variable is a proxy object is to
          # see if it responds to certain methods, as it forwards almost
          # everything to its target.
          revision.instance_variables.each do |ivar|
            proxy = revision.instance_variable_get ivar
            if !proxy.nil? && proxy.respond_to?(:proxy_respond_to?)
              revision.instance_variable_set ivar, nil
            end
          end
        end
      end

      private

      def audited_changes(for_touch: false)
        all_changes = if for_touch
          previous_changes
        elsif respond_to?(:changes_to_save)
          changes_to_save
        else
          changes
        end

        filtered_changes = \
          if audited_options[:only].present?
            all_changes.slice(*self.class.audited_columns)
          else
            all_changes.except(*self.class.non_audited_columns)
          end

        if for_touch && (last_audit = audits.last&.audited_changes)
          filtered_changes.reject! do |k, v|
            last_audit[k].to_json == v.to_json ||
            last_audit[k].to_json == v[1].to_json
          end
        end

        filtered_changes = redact_values(filtered_changes)
        filtered_changes = filter_encrypted_attrs(filtered_changes)
        filtered_changes = normalize_enum_changes(filtered_changes)
        filtered_changes.to_hash
      end

      def normalize_enum_changes(changes)
        return changes if Audited.store_synthesized_enums

        self.class.defined_enums.each do |name, values|
          if changes.has_key?(name)
            changes[name] = \
              if changes[name].is_a?(Array)
                changes[name].map { |v| values[v] }
              elsif rails_below?("5.0")
                changes[name]
              else
                values[changes[name]]
              end
          end
        end
        changes
      end

      def redact_values(filtered_changes)
        filter_attr_values(
          audited_changes: filtered_changes,
          attrs: Array(audited_options[:redacted]).map(&:to_s),
          placeholder: audited_options[:redaction_value] || REDACTED
        )
      end

      def filter_encrypted_attrs(filtered_changes)
        filter_attr_values(
          audited_changes: filtered_changes,
          attrs: respond_to?(:encrypted_attributes) ? Array(encrypted_attributes).map(&:to_s) : []
        )
      end

      # Replace values for given attrs to a placeholder and return modified hash
      #
      # @param audited_changes [Hash] Hash of changes to be saved to audited version record
      # @param attrs [Array<String>] Array of attrs, values of which will be replaced to placeholder value
      # @param placeholder [String] Placeholder to replace original attr values
      def filter_attr_values(audited_changes: {}, attrs: [], placeholder: "[FILTERED]")
        attrs.each do |attr|
          next unless audited_changes.key?(attr)

          changes = audited_changes[attr]
          values = changes.is_a?(Array) ? changes.map { placeholder } : placeholder

          audited_changes[attr] = values
        end

        audited_changes
      end

      def rails_below?(rails_version)
        Gem::Version.new(Rails::VERSION::STRING) < Gem::Version.new(rails_version)
      end

      def audits_to(version = nil)
        if version == :previous
          version = if audit_version
            audit_version - 1
          else
            previous = audits.descending.offset(1).first
            previous ? previous.version : 1
          end
        end
        audits.to_version(version)
      end

      def audit_create
        write_audit(action: "create", audited_changes: audited_attributes,
          comment: audit_comment)
      end

      def audit_update
        unless (changes = audited_changes).empty? && (audit_comment.blank? || audited_options[:update_with_comment_only] == false)
          write_audit(action: "update", audited_changes: changes,
            comment: audit_comment)
        end
      end

      def audit_touch
        unless (changes = audited_changes(for_touch: true)).empty?
          write_audit(action: "update", audited_changes: changes,
            comment: audit_comment)
        end
      end

      def audit_destroy
        unless new_record?
          write_audit(action: "destroy", audited_changes: audited_attributes,
            comment: audit_comment)
        end
      end

      def write_audit(attrs)
        self.audit_comment = nil

        if auditing_enabled
          attrs[:associated] = send(audit_associated_with) unless audit_associated_with.nil?

          run_callbacks(:audit) {
            audit = audits.create(attrs)
            combine_audits_if_needed if attrs[:action] != "create"
            audit
          }
        end
      end

      def presence_of_audit_comment
        if comment_required_state?
          errors.add(:audit_comment, :blank) unless audit_comment.present?
        end
      end

      def comment_required_state?
        auditing_enabled &&
          audited_changes.present? &&
          ((audited_options[:on].include?(:create) && new_record?) ||
          (audited_options[:on].include?(:update) && persisted? && changed?))
      end

      def combine_audits_if_needed
        max_audits = audited_options[:max_audits]
        if max_audits && (extra_count = audits.count - max_audits) > 0
          audits_to_combine = audits.limit(extra_count + 1)
          combine_audits(audits_to_combine)
        end
      end

      def require_comment
        if auditing_enabled && audit_comment.blank?
          errors.add(:audit_comment, :blank)
          throw(:abort)
        end
      end

      CALLBACKS.each do |attr_name|
        alias_method "#{attr_name}_callback".to_sym, attr_name
      end

      def auditing_enabled
        run_conditional_check(audited_options[:if]) &&
          run_conditional_check(audited_options[:unless], matching: false) &&
          self.class.auditing_enabled
      end

      def run_conditional_check(condition, matching: true)
        return true if condition.blank?
        return condition.call(self) == matching if condition.respond_to?(:call)
        return send(condition) == matching if respond_to?(condition.to_sym, true)

        true
      end

      def reconstruct_attributes(audits)
        attributes = {}
        audits.each { |audit| attributes.merge!(audit.new_attributes) }
        attributes
      end
    end

    module AuditedClassMethods
      # Returns an array of columns that are audited. See non_audited_columns
      def audited_columns
        @audited_columns ||= column_names - non_audited_columns
      end

      # We have to calculate this here since column_names may not be available when `audited` is called
      def non_audited_columns
        @non_audited_columns ||= calculate_non_audited_columns
      end

      def non_audited_columns=(columns)
        @audited_columns = nil # reset cached audited columns on assignment
        @non_audited_columns = columns.map(&:to_s)
      end

      # Executes the block with auditing disabled.
      #
      #   Foo.without_auditing do
      #     @foo.save
      #   end
      #
      def without_auditing
        auditing_was_enabled = class_auditing_enabled
        disable_auditing
        yield
      ensure
        enable_auditing if auditing_was_enabled
      end

      # Executes the block with auditing enabled.
      #
      #   Foo.with_auditing do
      #     @foo.save
      #   end
      #
      def with_auditing
        auditing_was_enabled = class_auditing_enabled
        enable_auditing
        yield
      ensure
        disable_auditing unless auditing_was_enabled
      end

      def disable_auditing
        self.auditing_enabled = false
      end

      def enable_auditing
        self.auditing_enabled = true
      end

      # All audit operations during the block are recorded as being
      # made by +user+. This is not model specific, the method is a
      # convenience wrapper around
      # @see Audit#as_user.
      def audit_as(user, &block)
        Audited.audit_class.as_user(user, &block)
      end

      def auditing_enabled
        class_auditing_enabled && Audited.auditing_enabled
      end

      def auditing_enabled=(val)
        Audited.store["#{table_name}_auditing_enabled"] = val
      end

      def default_ignored_attributes
        [primary_key, inheritance_column] | Audited.ignored_attributes
      end

      protected

      def normalize_audited_options
        audited_options[:on] = Array.wrap(audited_options[:on])
        audited_options[:on] = [:create, :update, :touch, :destroy] if audited_options[:on].empty?
        audited_options[:only] = Array.wrap(audited_options[:only]).map(&:to_s)
        audited_options[:except] = Array.wrap(audited_options[:except]).map(&:to_s)
        max_audits = audited_options[:max_audits] || Audited.max_audits
        audited_options[:max_audits] = Integer(max_audits).abs if max_audits
      end

      def calculate_non_audited_columns
        if audited_options[:only].present?
          (column_names | default_ignored_attributes) - audited_options[:only]
        elsif audited_options[:except].present?
          default_ignored_attributes | audited_options[:except]
        else
          default_ignored_attributes
        end
      end

      def class_auditing_enabled
        Audited.store.fetch("#{table_name}_auditing_enabled", true)
      end
    end
  end
end
