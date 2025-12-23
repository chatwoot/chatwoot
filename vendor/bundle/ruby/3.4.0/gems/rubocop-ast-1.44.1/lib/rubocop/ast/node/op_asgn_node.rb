# frozen_string_literal: true

module RuboCop
  module AST
    # A node extension for `op_asgn` nodes.
    # This will be used in place of a plain node when the builder constructs
    # the AST, making its methods available to all assignment nodes within RuboCop.
    class OpAsgnNode < Node
      # @return [AsgnNode] the assignment node
      def assignment_node
        node_parts[0]
      end
      alias lhs assignment_node

      # The name of the variable being assigned as a symbol.
      #
      # @return [Symbol] the name of the variable being assigned
      def name
        assignment_node.call_type? ? assignment_node.method_name : assignment_node.name
      end

      # The operator being used for assignment as a symbol.
      #
      # @return [Symbol] the assignment operator
      def operator
        node_parts[1]
      end

      # The expression being assigned to the variable.
      #
      # @return [Node] the expression being assigned.
      def expression
        node_parts.last
      end
      alias rhs expression
    end
  end
end
