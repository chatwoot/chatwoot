# frozen_string_literal: true

module RuboCop
  module AST
    # Common functionality for primitive literal nodes: `sym`, `str`,
    # `int`, `float`, `rational`...
    module BasicLiteralNode
      # Returns the value of the literal.
      #
      # @return [mixed] the value of the literal
      def value
        node_parts[0]
      end
    end
  end
end
