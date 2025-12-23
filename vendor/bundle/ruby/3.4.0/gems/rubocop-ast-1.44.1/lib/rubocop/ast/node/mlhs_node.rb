# frozen_string_literal: true

module RuboCop
  module AST
    # A node extension for `mlhs` nodes.
    # This will be used in place of a plain node when the builder constructs
    # the AST, making its methods available to all assignment nodes within RuboCop.
    class MlhsNode < Node
      # Returns all the assignment nodes on the left hand side (LHS) of a multiple assignment.
      # These are generally assignment nodes (`lvasgn`, `ivasgn`, `cvasgn`, `gvasgn`, `casgn`)
      # but can also be `send` nodes in case of `foo.bar, ... =` or `foo[:bar], ... =`,
      # or a `splat` node for `*, ... =`.
      #
      # @return [Array<Node>] the assignment nodes of the multiple assignment LHS
      def assignments
        child_nodes.flat_map do |node|
          if node.splat_type?
            # Anonymous splats have no children
            node.child_nodes.first || node
          elsif node.mlhs_type?
            node.assignments
          else
            node
          end
        end
      end
    end
  end
end
