# frozen_string_literal: true

module RuboCop
  module AST
    # Common functionality for nodes that can be used as modifiers:
    # `if`, `while`, `until`
    module ModifierNode
      # Checks whether the node is in a modifier form, i.e. a condition
      # trailing behind an expression.
      #
      # @return [Boolean] whether the node is a modifier
      def modifier_form?
        loc.end.nil?
      end
    end
  end
end
