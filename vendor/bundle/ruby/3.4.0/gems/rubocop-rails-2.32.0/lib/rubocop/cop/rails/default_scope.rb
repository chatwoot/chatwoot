# frozen_string_literal: true

module RuboCop
  module Cop
    module Rails
      # Looks for uses of `default_scope`.
      #
      # @example
      #   # bad
      #   default_scope -> { where(hidden: false) }
      #
      #   # good
      #   scope :published, -> { where(hidden: false) }
      #
      #   # bad
      #   def self.default_scope
      #     where(hidden: false)
      #   end
      #
      #   # good
      #   def self.published
      #     where(hidden: false)
      #   end
      #
      class DefaultScope < Base
        MSG = 'Avoid use of `default_scope`. It is better to use explicitly named scopes.'
        RESTRICT_ON_SEND = %i[default_scope].freeze

        def_node_matcher :method_call?, <<~PATTERN
          (send nil? :default_scope ...)
        PATTERN

        def_node_matcher :class_method_definition?, <<~PATTERN
          (defs _ :default_scope args ...)
        PATTERN

        def_node_matcher :eigenclass_method_definition?, <<~PATTERN
          (sclass (self) $(def :default_scope args ...))
        PATTERN

        def on_send(node)
          return unless method_call?(node)

          add_offense(node.loc.selector)
        end

        def on_defs(node)
          return unless class_method_definition?(node)

          add_offense(node.loc.name)
        end

        def on_sclass(node)
          eigenclass_method_definition?(node) do |default_scope|
            add_offense(default_scope.loc.name)
          end
        end
      end
    end
  end
end
