# frozen_string_literal: true

module RuboCop
  module AST
    # A node extension for `lvasgn`, `ivasgn`, `cvasgn`, and `gvasgn` nodes.
    # This will be used in place of a plain node when the builder constructs
    # the AST, making its methods available to all assignment nodes within RuboCop.
    class AsgnNode < Node
      # The name of the variable being assigned as a symbol.
      #
      # @return [Symbol] the name of the variable being assigned
      def name
        node_parts[0]
      end
      alias lhs name

      # The expression being assigned to the variable.
      #
      # @return [Node] the expression being assigned.
      def expression
        node_parts[1]
      end
      alias rhs expression
    end
  end
end
