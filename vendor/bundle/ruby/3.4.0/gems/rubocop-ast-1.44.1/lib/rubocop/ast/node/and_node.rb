# frozen_string_literal: true

module RuboCop
  module AST
    # A node extension for `until` nodes. This will be used in place of a plain
    # node when the builder constructs the AST, making its methods available
    # to all `until` nodes within RuboCop.
    class AndNode < Node
      include BinaryOperatorNode
      include PredicateOperatorNode

      # Returns the alternate operator of the `and` as a string.
      # Returns `and` for `&&` and vice versa.
      #
      # @return [String] the alternate of the `and` operator
      def alternate_operator
        logical_operator? ? SEMANTIC_AND : LOGICAL_AND
      end

      # Returns the inverse keyword of the `and` node as a string.
      # Returns `||` for `&&` and `or` for `and`.
      #
      # @return [String] the inverse of the `and` operator
      def inverse_operator
        logical_operator? ? LOGICAL_OR : SEMANTIC_OR
      end
    end
  end
end
