# frozen_string_literal: true

module RuboCop
  module Cop
    module Lint
      # Checks for the presence of empty expressions.
      #
      # @example
      #
      #   # bad
      #
      #   foo = ()
      #   if ()
      #     bar
      #   end
      #
      #   # good
      #
      #   foo = (some_expression)
      #   if (some_expression)
      #     bar
      #   end
      class EmptyExpression < Base
        MSG = 'Avoid empty expressions.'

        def on_begin(node)
          return unless empty_expression?(node)

          add_offense(node)
        end

        private

        def empty_expression?(begin_node)
          begin_node.children.empty?
        end
      end
    end
  end
end
