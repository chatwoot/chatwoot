# frozen_string_literal: true

module RuboCop
  module AST
    # A node extension for `or` nodes. This will be used in place of a plain
    # node when the builder constructs the AST, making its methods available
    # to all `or` nodes within RuboCop.
    class OrNode < Node
      include BinaryOperatorNode
      include PredicateOperatorNode

      # Returns the alternate operator of the `or` as a string.
      # Returns `or` for `||` and vice versa.
      #
      # @return [String] the alternate of the `or` operator
      def alternate_operator
        logical_operator? ? SEMANTIC_OR : LOGICAL_OR
      end

      # Returns the inverse keyword of the `or` node as a string.
      # Returns `and` for `or` and `&&` for `||`.
      #
      # @return [String] the inverse of the `or` operator
      def inverse_operator
        logical_operator? ? LOGICAL_AND : SEMANTIC_AND
      end
    end
  end
end
