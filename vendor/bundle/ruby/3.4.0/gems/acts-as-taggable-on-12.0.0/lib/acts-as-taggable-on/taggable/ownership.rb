# frozen_string_literal: true

module ActsAsTaggableOn
  module Taggable
    module Ownership
      extend ActiveSupport::Concern

      included do
        after_save :save_owned_tags

        initialize_acts_as_taggable_on_ownership
      end

      class_methods do
        def acts_as_taggable_on(*args)
          initialize_acts_as_taggable_on_ownership
          super(*args)
        end

        def initialize_acts_as_taggable_on_ownership
          tag_types.map(&:to_s).each do |tag_type|
            class_eval <<-RUBY, __FILE__, __LINE__ + 1
            def #{tag_type}_from(owner)
              owner_tag_list_on(owner, '#{tag_type}')
            end
            RUBY
          end
        end
      end

      def owner_tags(owner)
        scope = if owner.nil?
                  base_tags
                else
                  base_tags.where(
                    ActsAsTaggableOn::Tagging.table_name.to_s => {
                      tagger_id: owner.id,
                      tagger_type: owner.class.base_class.to_s
                    }
                  )
                end

        # when preserving tag order, return tags in created order
        # if we added the order to the association this would always apply
        if self.class.preserve_tag_order?
          scope.order("#{ActsAsTaggableOn::Tagging.table_name}.id")
        else
          scope
        end
      end

      def owner_tags_on(owner, context)
        owner_tags(owner).where(
          ActsAsTaggableOn::Tagging.table_name.to_s => {
            context: context
          }
        )
      end

      def cached_owned_tag_list_on(context)
        variable_name = "@owned_#{context}_list"
        (instance_variable_defined?(variable_name) && instance_variable_get(variable_name)) || instance_variable_set(
          variable_name, {}
        )
      end

      def owner_tag_list_on(owner, context)
        add_custom_context(context)

        cache = cached_owned_tag_list_on(context)

        cache[owner] ||= ActsAsTaggableOn::TagList.new(*owner_tags_on(owner, context).map(&:name))
      end

      def set_owner_tag_list_on(owner, context, new_list)
        add_custom_context(context)

        cache = cached_owned_tag_list_on(context)

        cache[owner] = ActsAsTaggableOn.default_parser.new(new_list).parse
      end

      def reload(*args)
        self.class.tag_types.each do |context|
          instance_variable_set("@owned_#{context}_list", nil)
        end

        super(*args)
      end

      def save_owned_tags
        tagging_contexts.each do |context|
          cached_owned_tag_list_on(context).each do |owner, tag_list|
            # Find existing tags or create non-existing tags:
            tags = find_or_create_tags_from_list_with_context(tag_list.uniq, context)

            # Tag objects for owned tags
            owned_tags = owner_tags_on(owner, context).to_a

            # Tag maintenance based on whether preserving the created order of tags
            old_tags = owned_tags - tags
            new_tags = tags - owned_tags
            if self.class.preserve_tag_order?

              shared_tags = owned_tags & tags

              if shared_tags.any? && tags[0...shared_tags.size] != shared_tags
                index = shared_tags.each_with_index do |_, i|
                  break i unless shared_tags[i] == tags[i]
                end

                # Update arrays of tag objects
                old_tags |= owned_tags.from(index)
                new_tags |= owned_tags.from(index) & shared_tags

                # Order the array of tag objects to match the tag list
                new_tags = tags.map do |t|
                  new_tags.find do |n|
                    n.name.downcase == t.name.downcase
                  end
                end.compact
              end
            else
              # Delete discarded tags and create new tags
            end

            # Find all taggings that belong to the taggable (self), are owned by the owner,
            # have the correct context, and are removed from the list.
            if old_tags.present?
              ActsAsTaggableOn::Tagging.where(taggable_id: id, taggable_type: self.class.base_class.to_s,
                                              tagger_type: owner.class.base_class.to_s, tagger_id: owner.id,
                                              tag_id: old_tags, context: context).destroy_all
            end

            # Create new taggings:
            new_tags.each do |tag|
              taggings.create!(tag_id: tag.id, context: context.to_s, tagger: owner, taggable: self)
            end
          end
        end

        true
      end
    end
  end
end
