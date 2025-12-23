# frozen_string_literal: true

module RuboCop
  module AST
    # A node extension for `while` nodes. This will be used in place of a plain
    # node when the builder constructs the AST, making its methods available
    # to all `while` nodes within RuboCop.
    class WhileNode < Node
      include ConditionalNode
      include ModifierNode

      # Returns the keyword of the `while` statement as a string.
      #
      # @return [String] the keyword of the `while` statement
      def keyword
        'while'
      end

      # Returns the inverse keyword of the `while` node as a string.
      # Returns `until` for `while` nodes and vice versa.
      #
      # @return [String] the inverse keyword of the `while` statement
      def inverse_keyword
        'until'
      end

      # Checks whether the `until` node has a `do` keyword.
      #
      # @return [Boolean] whether the `until` node has a `do` keyword
      def do?
        loc_is?(:begin, 'do')
      end
    end
  end
end
