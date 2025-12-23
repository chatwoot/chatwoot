# frozen_string_literal: true

module ActsAsTaggableOn
  module Tagger
    extend ActiveSupport::Concern

    class_methods do
      ##
      # Make a model a tagger. This allows an instance of a model to claim ownership
      # of tags.
      #
      # Example:
      #   class User < ActiveRecord::Base
      #     acts_as_tagger
      #   end
      def acts_as_tagger(opts = {})
        class_eval do
          owned_taggings_scope = opts.delete(:scope)

          has_many :owned_taggings, owned_taggings_scope,
                   **opts.merge(
                     as: :tagger,
                     class_name: '::ActsAsTaggableOn::Tagging',
                     dependent: :destroy
                   )

          has_many :owned_tags, -> { distinct },
                   class_name: '::ActsAsTaggableOn::Tag',
                   source: :tag,
                   through: :owned_taggings
        end

        include ActsAsTaggableOn::Tagger::InstanceMethods
        extend ActsAsTaggableOn::Tagger::SingletonMethods
      end

      def tagger?
        false
      end

      alias is_tagger? tagger?
    end

    module InstanceMethods
      ##
      # Tag a taggable model with tags that are owned by the tagger.
      #
      # @param taggable The object that will be tagged
      # @param [Hash] options An hash with options. Available options are:
      #               * <tt>:with</tt> - The tags that you want to
      #               * <tt>:on</tt>   - The context on which you want to tag
      #
      # Example:
      #   @user.tag(@photo, :with => "paris, normandy", :on => :locations)
      def tag(taggable, opts = {})
        opts.reverse_merge!(force: true)
        skip_save = opts.delete(:skip_save)
        return false unless taggable.respond_to?(:is_taggable?) && taggable.is_taggable?

        raise 'You need to specify a tag context using :on' unless opts.key?(:on)
        raise 'You need to specify some tags using :with' unless opts.key?(:with)
        unless opts[:force] || taggable.tag_types.include?(opts[:on])
          raise "No context :#{opts[:on]} defined in #{taggable.class}"
        end

        taggable.set_owner_tag_list_on(self, opts[:on].to_s, opts[:with])
        taggable.save unless skip_save
      end

      def tagger?
        self.class.is_tagger?
      end

      alias is_tagger? tagger?
    end

    module SingletonMethods
      def tagger?
        true
      end

      alias is_tagger? tagger?
    end
  end
end
