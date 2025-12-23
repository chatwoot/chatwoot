# frozen_string_literal: true

module RuboCop
  module AST
    # Common functionality for nodes that are predicates:
    # `or`, `and` ...
    module PredicateOperatorNode
      LOGICAL_AND = '&&'
      private_constant :LOGICAL_AND
      SEMANTIC_AND = 'and'
      private_constant :SEMANTIC_AND
      LOGICAL_OR = '||'
      private_constant :LOGICAL_OR
      SEMANTIC_OR = 'or'
      private_constant :SEMANTIC_OR

      LOGICAL_OPERATORS = [LOGICAL_AND, LOGICAL_OR].freeze
      private_constant :LOGICAL_OPERATORS
      SEMANTIC_OPERATORS = [SEMANTIC_AND, SEMANTIC_OR].freeze
      private_constant :SEMANTIC_OPERATORS

      # Returns the operator as a string.
      #
      # @return [String] the operator
      def operator
        loc.operator.source
      end

      # Checks whether this is a logical operator.
      #
      # @return [Boolean] whether this is a logical operator
      def logical_operator?
        LOGICAL_OPERATORS.include?(operator)
      end

      # Checks whether this is a semantic operator.
      #
      # @return [Boolean] whether this is a semantic operator
      def semantic_operator?
        SEMANTIC_OPERATORS.include?(operator)
      end
    end
  end
end
