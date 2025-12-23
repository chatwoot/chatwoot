# frozen_string_literal: true

module RuboCop
  module AST
    # A node extension for `casgn` nodes.
    # This will be used in place of a plain node when the builder constructs
    # the AST, making its methods available to all assignment nodes within RuboCop.
    class CasgnNode < Node
      include ConstantNode

      alias name short_name
      alias lhs short_name

      # The expression being assigned to the variable.
      #
      # @return [Node] the expression being assigned.
      def expression
        node_parts[2]
      end
      alias rhs expression
    end
  end
end
