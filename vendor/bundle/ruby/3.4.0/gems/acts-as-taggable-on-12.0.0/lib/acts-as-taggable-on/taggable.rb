# frozen_string_literal: true

module ActsAsTaggableOn
  module Taggable
    def taggable?
      false
    end

    ##
    # This is an alias for calling <tt>acts_as_taggable_on :tags</tt>.
    #
    # Example:
    #   class Book < ActiveRecord::Base
    #     acts_as_taggable
    #   end
    def acts_as_taggable
      acts_as_taggable_on :tags
    end

    ##
    # This is an alias for calling <tt>acts_as_ordered_taggable_on :tags</tt>.
    #
    # Example:
    #   class Book < ActiveRecord::Base
    #     acts_as_ordered_taggable
    #   end
    def acts_as_ordered_taggable
      acts_as_ordered_taggable_on :tags
    end

    ##
    # Make a model taggable on specified contexts.
    #
    # @param [Array] tag_types An array of taggable contexts
    #
    # Example:
    #   class User < ActiveRecord::Base
    #     acts_as_taggable_on :languages, :skills
    #   end
    def acts_as_taggable_on(*tag_types)
      taggable_on(false, tag_types)
    end

    ##
    # Make a model taggable on specified contexts
    # and preserves the order in which tags are created
    #
    # @param [Array] tag_types An array of taggable contexts
    #
    # Example:
    #   class User < ActiveRecord::Base
    #     acts_as_ordered_taggable_on :languages, :skills
    #   end
    def acts_as_ordered_taggable_on(*tag_types)
      taggable_on(true, tag_types)
    end

    def acts_as_taggable_tenant(tenant)
      if taggable?
      else
        class_attribute :tenant_column
      end
      self.tenant_column = tenant

      # each of these add context-specific methods and must be
      # called on each call of taggable_on
      include Core
      include Collection
      include Caching
      include Ownership
      include Related
    end

    private

    # Make a model taggable on specified contexts
    # and optionally preserves the order in which tags are created
    #
    # Separate methods used above for backwards compatibility
    # so that the original acts_as_taggable_on method is unaffected
    # as it's not possible to add another argument to the method
    # without the tag_types being enclosed in square brackets
    #
    # NB: method overridden in core module in order to create tag type
    #     associations and methods after this logic has executed
    #
    def taggable_on(preserve_tag_order, *tag_types)
      tag_types = tag_types.to_a.flatten.compact.map(&:to_sym)

      if taggable?
        self.tag_types = (self.tag_types + tag_types).uniq
        self.preserve_tag_order = preserve_tag_order
      else
        class_eval do
          class_attribute :tag_types
          class_attribute :preserve_tag_order
          class_attribute :tenant_column
          self.tag_types = tag_types
          self.preserve_tag_order = preserve_tag_order

          has_many :taggings, as: :taggable, dependent: :destroy, class_name: '::ActsAsTaggableOn::Tagging'
          has_many :base_tags, through: :taggings, source: :tag, class_name: '::ActsAsTaggableOn::Tag'

          def self.taggable?
            true
          end
        end
      end

      # each of these add context-specific methods and must be
      # called on each call of taggable_on
      include Core
      include Collection
      include Caching
      include Ownership
      include Related
    end
  end
end
