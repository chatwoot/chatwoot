# frozen_string_literal: true

module RuboCop
  module AST
    # A node extension for `masgn` nodes.
    # This will be used in place of a plain node when the builder constructs
    # the AST, making its methods available to all assignment nodes within RuboCop.
    class MasgnNode < Node
      # @return [MlhsNode] the `mlhs` node
      def lhs
        # The first child is a `mlhs` node
        node_parts[0]
      end

      # @return [Array<Node>] the assignment nodes of the multiple assignment
      def assignments
        lhs.assignments
      end

      # @return [Array<Symbol>] names of all the variables being assigned
      def names
        assignments.map do |assignment|
          if assignment.type?(:send, :indexasgn)
            assignment.method_name
          else
            assignment.name
          end
        end
      end

      # The RHS (right hand side) of the multiple assignment. This returns
      # the nodes as parsed: either a single node if the RHS has a single value,
      # or an `array` node containing multiple nodes.
      #
      # NOTE: Due to how parsing works, `expression` will return the same for
      # `a, b = x, y` and `a, b = [x, y]`.
      #
      # @return [Node] the right hand side of a multiple assignment.
      def expression
        node_parts[1]
      end
      alias rhs expression

      # In contrast to `expression`, `values` always returns a Ruby array
      # containing all the nodes being assigned on the RHS.
      #
      # Literal arrays are considered a singular value; but unlike `expression`,
      # implied `array` nodes from assigning multiple values on the RHS are treated
      # as separate.
      #
      # @return [Array<Node>] individual values being assigned on the RHS of the multiple assignment
      def values
        multiple_rhs? ? expression.children : [expression]
      end

      private

      def multiple_rhs?
        expression.array_type? && !expression.bracketed?
      end
    end
  end
end
