# frozen_string_literal: true

module RuboCop
  module Cop
    module Rails
      # Looks for `has_many` or `has_one` associations that don't
      # specify a `:dependent` option.
      #
      # It doesn't register an offense if `:through` or `dependent: nil`
      # is specified, or if the model is read-only.
      #
      # @example
      #   # bad
      #   class User < ActiveRecord::Base
      #     has_many :comments
      #     has_one :avatar
      #   end
      #
      #   # good
      #   class User < ActiveRecord::Base
      #     has_many :comments, dependent: :restrict_with_exception
      #     has_one :avatar, dependent: :destroy
      #     has_many :articles, dependent: nil
      #     has_many :patients, through: :appointments
      #   end
      #
      #   class User < ActiveRecord::Base
      #     has_many :comments
      #     has_one :avatar
      #
      #     def readonly?
      #       true
      #     end
      #   end
      class HasManyOrHasOneDependent < Base
        MSG = 'Specify a `:dependent` option.'
        RESTRICT_ON_SEND = %i[has_many has_one].freeze

        def_node_search :active_resource_class?, <<~PATTERN
          (const (const {nil? cbase} :ActiveResource) :Base)
        PATTERN

        def_node_matcher :association_without_options?, <<~PATTERN
          (send _ {:has_many :has_one} _)
        PATTERN

        def_node_matcher :association_with_options?, <<~PATTERN
          (send _ {:has_many :has_one} ... (hash $...))
        PATTERN

        def_node_matcher :dependent_option?, <<~PATTERN
          (pair (sym :dependent) {!nil (nil)})
        PATTERN

        def_node_matcher :present_option?, <<~PATTERN
          (pair (sym :through) !nil)
        PATTERN

        def_node_matcher :with_options_block, <<~PATTERN
          (block
            (send nil? :with_options
              (hash $...))
            (args _?) ...)
        PATTERN

        def_node_matcher :association_extension_block?, <<~PATTERN
          (block
            (send nil? :has_many _)
            (args) ...)
        PATTERN

        def_node_matcher :readonly?, <<~PATTERN
          (def :readonly?
            (args)
            (true))
        PATTERN

        def on_send(node)
          return if active_resource?(node.parent) || readonly_model?(node)
          return if !association_without_options?(node) && valid_options?(association_with_options?(node))
          return if valid_options_in_with_options_block?(node)

          add_offense(node.loc.selector)
        end

        private

        def readonly_model?(node)
          return false unless (parent = node.parent)

          parent.each_descendant(:def).any? { |def_node| readonly?(def_node) }
        end

        def valid_options_in_with_options_block?(node)
          return true unless node.parent

          n = node.parent.begin_type? || association_extension_block?(node.parent) ? node.parent.parent : node.parent

          contain_valid_options_in_with_options_block?(n)
        end

        def contain_valid_options_in_with_options_block?(node)
          if (options = with_options_block(node))
            return true if valid_options?(options)

            return false unless node.parent

            return true if contain_valid_options_in_with_options_block?(node.parent.parent)
          end

          false
        end

        def valid_options?(options)
          return false if options.nil?

          options = extract_option_if_kwsplat(options)

          return true unless options
          return true if options.any? do |o|
            dependent_option?(o) || present_option?(o)
          end

          false
        end

        def extract_option_if_kwsplat(options)
          if options.first.kwsplat_type? && options.first.children.first.hash_type?
            return options.first.children.first.pairs
          end

          options
        end

        def active_resource?(node)
          return false if node.nil?

          active_resource_class?(node)
        end
      end
    end
  end
end
