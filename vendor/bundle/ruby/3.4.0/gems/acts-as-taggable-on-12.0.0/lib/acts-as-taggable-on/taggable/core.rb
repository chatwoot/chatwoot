# frozen_string_literal: true

require_relative 'tagged_with_query'
require_relative 'tag_list_type'

module ActsAsTaggableOn
  module Taggable
    module Core
      extend ActiveSupport::Concern

      included do
          attr_writer :custom_contexts

          after_save :save_tags

        initialize_acts_as_taggable_on_core
      end

      class_methods do
        def initialize_acts_as_taggable_on_core
          include taggable_mixin
          tag_types.map(&:to_s).each do |tags_type|
            tag_type = tags_type.to_s.singularize
            context_taggings = "#{tag_type}_taggings".to_sym
            context_tags = tags_type.to_sym
            taggings_order = (preserve_tag_order? ? "#{ActsAsTaggableOn::Tagging.table_name}.id" : [])

            class_eval do
              # when preserving tag order, include order option so that for a 'tags' context
              # the associations tag_taggings & tags are always returned in created order
              has_many context_taggings, -> { includes(:tag).order(taggings_order).where(context: tags_type) },
                       as: :taggable,
                       class_name: 'ActsAsTaggableOn::Tagging',
                       dependent: :destroy,
                       after_add: :dirtify_tag_list,
                       after_remove: :dirtify_tag_list

              has_many context_tags, -> { order(taggings_order) },
                       class_name: 'ActsAsTaggableOn::Tag',
                       through: context_taggings,
                       source: :tag

              attribute "#{tags_type.singularize}_list".to_sym, ActsAsTaggableOn::Taggable::TagListType.new
            end

            taggable_mixin.class_eval <<-RUBY, __FILE__, __LINE__ + 1
            def #{tag_type}_list
              tag_list_on('#{tags_type}')
            end

            def #{tag_type}_list=(new_tags)
              parsed_new_list = ActsAsTaggableOn.default_parser.new(new_tags).parse

              if self.class.preserve_tag_order? || (parsed_new_list.sort != #{tag_type}_list.sort)
                unless #{tag_type}_list_changed?
                  @attributes["#{tag_type}_list"] = ActiveModel::Attribute.from_user("#{tag_type}_list", #{tag_type}_list, ActsAsTaggableOn::Taggable::TagListType.new)
                end
                write_attribute("#{tag_type}_list", parsed_new_list)
              end

              set_tag_list_on('#{tags_type}', new_tags)
            end

            def all_#{tags_type}_list
              all_tags_list_on('#{tags_type}')
            end

            private
            def dirtify_tag_list(tagging)
              attribute_will_change! tagging.context.singularize+"_list"
            end
            RUBY
          end
        end

        def taggable_on(preserve_tag_order, *tag_types)
          super(preserve_tag_order, *tag_types)
          initialize_acts_as_taggable_on_core
        end

        # all column names are necessary for PostgreSQL group clause
        def grouped_column_names_for(object)
          object.column_names.map { |column| "#{object.table_name}.#{column}" }.join(', ')
        end

        ##
        # Return a scope of objects that are tagged with the specified tags.
        #
        # @param tags The tags that we want to query for
        # @param [Hash] options A hash of options to alter you query:
        #                       * <tt>:exclude</tt> - if set to true, return objects that are *NOT* tagged with the specified tags
        #                       * <tt>:any</tt> - if set to true, return objects that are tagged with *ANY* of the specified tags
        #                       * <tt>:order_by_matching_tag_count</tt> - if set to true and used with :any, sort by objects matching the most tags, descending
        #                       * <tt>:match_all</tt> - if set to true, return objects that are *ONLY* tagged with the specified tags
        #                       * <tt>:owned_by</tt> - return objects that are *ONLY* owned by the owner
        #                       * <tt>:start_at</tt> - Restrict the tags to those created after a certain time
        #                       * <tt>:end_at</tt> - Restrict the tags to those created before a certain time
        #
        # Example:
        #   User.tagged_with(["awesome", "cool"])                     # Users that are tagged with awesome and cool
        #   User.tagged_with(["awesome", "cool"], :exclude => true)   # Users that are not tagged with awesome or cool
        #   User.tagged_with(["awesome", "cool"], :any => true)       # Users that are tagged with awesome or cool
        #   User.tagged_with(["awesome", "cool"], :any => true, :order_by_matching_tag_count => true)  # Sort by users who match the most tags, descending
        #   User.tagged_with(["awesome", "cool"], :match_all => true) # Users that are tagged with just awesome and cool
        #   User.tagged_with(["awesome", "cool"], :owned_by => foo ) # Users that are tagged with just awesome and cool by 'foo'
        #   User.tagged_with(["awesome", "cool"], :owned_by => foo, :start_at => Date.today ) # Users that are tagged with just awesome, cool by 'foo' and starting today
        def tagged_with(tags, options = {})
          tag_list = ActsAsTaggableOn.default_parser.new(tags).parse
          options = options.dup

          return none if tag_list.empty?

          ::ActsAsTaggableOn::Taggable::TaggedWithQuery.build(self, ActsAsTaggableOn::Tag, ActsAsTaggableOn::Tagging,
                                                              tag_list, options)
        end

        def is_taggable?
          true
        end

        def taggable_mixin
          @taggable_mixin ||= Module.new
        end
      end

      # all column names are necessary for PostgreSQL group clause
      def grouped_column_names_for(object)
        self.class.grouped_column_names_for(object)
      end

      def custom_contexts
        @custom_contexts ||= taggings.map(&:context).uniq
      end

      def is_taggable?
        self.class.is_taggable?
      end

      def add_custom_context(value)
        unless custom_contexts.include?(value.to_s) || self.class.tag_types.map(&:to_s).include?(value.to_s)
          custom_contexts << value.to_s
        end
      end

      def cached_tag_list_on(context)
        self["cached_#{context.to_s.singularize}_list"]
      end

      def tag_list_cache_set_on(context)
        variable_name = "@#{context.to_s.singularize}_list"
        instance_variable_defined?(variable_name) && instance_variable_get(variable_name)
      end

      def tag_list_cache_on(context)
        variable_name = "@#{context.to_s.singularize}_list"
        if instance_variable_get(variable_name)
          instance_variable_get(variable_name)
        elsif cached_tag_list_on(context) && ensure_included_cache_methods! && self.class.caching_tag_list_on?(context)
          instance_variable_set(variable_name, ActsAsTaggableOn.default_parser.new(cached_tag_list_on(context)).parse)
        else
          instance_variable_set(variable_name, ActsAsTaggableOn::TagList.new(tags_on(context).map(&:name)))
        end
      end

      def tag_list_on(context)
        add_custom_context(context)
        tag_list_cache_on(context)
      end

      def all_tags_list_on(context)
        variable_name = "@all_#{context.to_s.singularize}_list"
        if instance_variable_defined?(variable_name) && instance_variable_get(variable_name)
          return instance_variable_get(variable_name)
        end

        instance_variable_set(variable_name, ActsAsTaggableOn::TagList.new(all_tags_on(context).map(&:name)).freeze)
      end

      ##
      # Returns all tags of a given context
      def all_tags_on(context)
        tagging_table_name = ActsAsTaggableOn::Tagging.table_name

        opts = ["#{tagging_table_name}.context = ?", context.to_s]
        scope = base_tags.where(opts)

        if ActsAsTaggableOn::Utils.using_postgresql?
          group_columns = grouped_column_names_for(ActsAsTaggableOn::Tag)
          scope.order(Arel.sql("max(#{tagging_table_name}.created_at)")).group(group_columns)
        else
          scope.group("#{ActsAsTaggableOn::Tag.table_name}.#{ActsAsTaggableOn::Tag.primary_key}")
        end.to_a
      end

      ##
      # Returns all tags that are not owned of a given context
      def tags_on(context)
        scope = base_tags.where([
                                  "#{ActsAsTaggableOn::Tagging.table_name}.context = ? AND #{ActsAsTaggableOn::Tagging.table_name}.tagger_id IS NULL", context.to_s
                                ])
        # when preserving tag order, return tags in created order
        # if we added the order to the association this would always apply
        scope = scope.order("#{ActsAsTaggableOn::Tagging.table_name}.id") if self.class.preserve_tag_order?
        scope
      end

      def set_tag_list_on(context, new_list)
        add_custom_context(context)

        variable_name = "@#{context.to_s.singularize}_list"

        parsed_new_list = ActsAsTaggableOn.default_parser.new(new_list).parse

        instance_variable_set(variable_name, parsed_new_list)
      end

      def tagging_contexts
        self.class.tag_types.map(&:to_s) + custom_contexts
      end

      def taggable_tenant
        public_send(self.class.tenant_column) if self.class.tenant_column
      end

      def reload(*args)
        self.class.tag_types.each do |context|
          instance_variable_set("@#{context.to_s.singularize}_list", nil)
          instance_variable_set("@all_#{context.to_s.singularize}_list", nil)
        end

        super(*args)
      end

      ##
      # Find existing tags or create non-existing tags
      def load_tags(tag_list)
        ActsAsTaggableOn::Tag.find_or_create_all_with_like_by_name(tag_list)
      end

      def save_tags
        tagging_contexts.each do |context|
          next unless tag_list_cache_set_on(context)

          # List of currently assigned tag names
          tag_list = tag_list_cache_on(context).uniq

          # Find existing tags or create non-existing tags:
          tags = find_or_create_tags_from_list_with_context(tag_list, context)

          # Tag objects for currently assigned tags
          current_tags = tags_on(context)

          # Tag maintenance based on whether preserving the created order of tags
          old_tags = current_tags - tags
          new_tags = tags - current_tags
          if self.class.preserve_tag_order?

            shared_tags = current_tags & tags

            if shared_tags.any? && tags[0...shared_tags.size] != shared_tags
              index = shared_tags.each_with_index do |_, i|
                break i unless shared_tags[i] == tags[i]
              end

              # Update arrays of tag objects
              old_tags |= current_tags[index...current_tags.size]
              new_tags |= current_tags[index...current_tags.size] & shared_tags

              # Order the array of tag objects to match the tag list
              new_tags = tags.map do |t|
                new_tags.find { |n| n.name.downcase == t.name.downcase }
              end.compact
            end
          else
            # Delete discarded tags and create new tags
          end

          # Destroy old taggings:
          taggings.not_owned.by_context(context).where(tag_id: old_tags).destroy_all if old_tags.present?

          # Create new taggings:
          new_tags.each do |tag|
            if taggable_tenant
              taggings.create!(tag_id: tag.id, context: context.to_s, taggable: self, tenant: taggable_tenant)
            else
              taggings.create!(tag_id: tag.id, context: context.to_s, taggable: self)
            end
          end
        end

        true
      end

      private

      def ensure_included_cache_methods!
        self.class.columns
      end

      # Filters the tag lists from the attribute names.
      def attributes_for_update(attribute_names)
        tag_lists = tag_types.map { |tags_type| "#{tags_type.to_s.singularize}_list" }
        super.delete_if { |attr| tag_lists.include? attr }
      end

      # Filters the tag lists from the attribute names.
      def attributes_for_create(attribute_names)
        tag_lists = tag_types.map { |tags_type| "#{tags_type.to_s.singularize}_list" }
        super.delete_if { |attr| tag_lists.include? attr }
      end

      ##
      # Override this hook if you wish to subclass {ActsAsTaggableOn::Tag} --
      # context is provided so that you may conditionally use a Tag subclass
      # only for some contexts.
      #
      # @example Custom Tag class for one context
      #   class Company < ActiveRecord::Base
      #     acts_as_taggable_on :markets, :locations
      #
      #     def find_or_create_tags_from_list_with_context(tag_list, context)
      #       if context.to_sym == :markets
      #         MarketTag.find_or_create_all_with_like_by_name(tag_list)
      #       else
      #         super
      #       end
      #     end
      #
      # @param [Array<String>] tag_list Tags to find or create
      # @param [Symbol] context The tag context for the tag_list
      def find_or_create_tags_from_list_with_context(tag_list, _context)
        load_tags(tag_list)
      end
    end
  end
end
