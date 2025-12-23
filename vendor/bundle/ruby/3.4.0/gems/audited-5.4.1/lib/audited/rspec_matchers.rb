# frozen_string_literal: true

module Audited
  module RspecMatchers
    # Ensure that the model is audited.
    #
    # Options:
    # * <tt>associated_with</tt> - tests that the audit makes use of the associated_with option
    # * <tt>only</tt> - tests that the audit makes use of the only option *Overrides <tt>except</tt> option*
    # * <tt>except</tt> - tests that the audit makes use of the except option
    # * <tt>requires_comment</tt> - if specified, then the audit must require comments through the <tt>audit_comment</tt> attribute
    # * <tt>on</tt> - tests that the audit makes use of the on option with specified parameters
    #
    # Example:
    #   it { should be_audited }
    #   it { should be_audited.associated_with(:user) }
    #   it { should be_audited.only(:field_name) }
    #   it { should be_audited.except(:password) }
    #   it { should be_audited.requires_comment }
    #   it { should be_audited.on(:create).associated_with(:user).except(:password) }
    #
    def be_audited
      AuditMatcher.new
    end

    # Ensure that the model has associated audits
    #
    # Example:
    #   it { should have_associated_audits }
    #
    def have_associated_audits
      AssociatedAuditMatcher.new
    end

    class AuditMatcher # :nodoc:
      def initialize
        @options = {}
      end

      def associated_with(model)
        @options[:associated_with] = model
        self
      end

      def only(*fields)
        @options[:only] = fields.flatten.map(&:to_s)
        self
      end

      def except(*fields)
        @options[:except] = fields.flatten.map(&:to_s)
        self
      end

      def requires_comment
        @options[:comment_required] = true
        self
      end

      def on(*actions)
        @options[:on] = actions.flatten.map(&:to_sym)
        self
      end

      def matches?(subject)
        @subject = subject
        auditing_enabled? && required_checks_for_options_satisfied?
      end

      def failure_message
        "Expected #{@expectation}"
      end

      def negative_failure_message
        "Did not expect #{@expectation}"
      end

      alias_method :failure_message_when_negated, :negative_failure_message

      def description
        description = "audited"
        description += " associated with #{@options[:associated_with]}" if @options.key?(:associated_with)
        description += " only => #{@options[:only].join ", "}" if @options.key?(:only)
        description += " except => #{@options[:except].join(", ")}" if @options.key?(:except)
        description += " requires audit_comment" if @options.key?(:comment_required)

        description
      end

      protected

      def expects(message)
        @expectation = message
      end

      def auditing_enabled?
        expects "#{model_class} to be audited"
        model_class.respond_to?(:auditing_enabled) && model_class.auditing_enabled
      end

      def model_class
        @subject.class
      end

      def associated_with_model?
        expects "#{model_class} to record audits to associated model #{@options[:associated_with]}"
        model_class.audit_associated_with == @options[:associated_with]
      end

      def records_changes_to_specified_fields?
        ignored_fields = build_ignored_fields_from_options

        expects "non audited columns (#{model_class.non_audited_columns.inspect}) to match (#{ignored_fields})"
        model_class.non_audited_columns.to_set == ignored_fields.to_set
      end

      def comment_required_valid?
        expects "to require audit_comment before #{model_class.audited_options[:on]} when comment required"
        validate_callbacks_include_presence_of_comment? && destroy_callbacks_include_comment_required?
      end

      def only_audit_on_designated_callbacks?
        {
          create: [:after, :audit_create],
          update: [:before, :audit_update],
          destroy: [:before, :audit_destroy]
        }.map do |(action, kind_callback)|
          kind, callback = kind_callback
          callbacks_for(action, kind: kind).include?(callback) if @options[:on].include?(action)
        end.compact.all?
      end

      def validate_callbacks_include_presence_of_comment?
        if @options[:comment_required] && audited_on_create_or_update?
          callbacks_for(:validate).include?(:presence_of_audit_comment)
        else
          true
        end
      end

      def audited_on_create_or_update?
        model_class.audited_options[:on].include?(:create) || model_class.audited_options[:on].include?(:update)
      end

      def destroy_callbacks_include_comment_required?
        if @options[:comment_required] && model_class.audited_options[:on].include?(:destroy)
          callbacks_for(:destroy).include?(:require_comment)
        else
          true
        end
      end

      def requires_comment_before_callbacks?
        [:create, :update, :destroy].map do |action|
          if @options[:comment_required] && model_class.audited_options[:on].include?(action)
            callbacks_for(action).include?(:require_comment)
          end
        end.compact.all?
      end

      def callbacks_for(action, kind: :before)
        model_class.send("_#{action}_callbacks").select { |cb| cb.kind == kind }.map(&:filter)
      end

      def build_ignored_fields_from_options
        default_ignored_attributes = model_class.default_ignored_attributes

        if @options[:only].present?
          (default_ignored_attributes | model_class.column_names) - @options[:only]
        elsif @options[:except].present?
          default_ignored_attributes | @options[:except]
        else
          default_ignored_attributes
        end
      end

      def required_checks_for_options_satisfied?
        {
          only: :records_changes_to_specified_fields?,
          except: :records_changes_to_specified_fields?,
          comment_required: :comment_required_valid?,
          associated_with: :associated_with_model?,
          on: :only_audit_on_designated_callbacks?
        }.map do |(option, check)|
          send(check) if @options[option].present?
        end.compact.all?
      end
    end

    class AssociatedAuditMatcher # :nodoc:
      def matches?(subject)
        @subject = subject

        association_exists?
      end

      def failure_message
        "Expected #{model_class} to have associated audits"
      end

      def negative_failure_message
        "Expected #{model_class} to not have associated audits"
      end

      alias_method :failure_message_when_negated, :negative_failure_message

      def description
        "has associated audits"
      end

      protected

      def model_class
        @subject.class
      end

      def reflection
        model_class.reflect_on_association(:associated_audits)
      end

      def association_exists?
        !reflection.nil? &&
          reflection.macro == :has_many &&
          reflection.options[:class_name] == Audited.audit_class.name
      end
    end
  end
end
