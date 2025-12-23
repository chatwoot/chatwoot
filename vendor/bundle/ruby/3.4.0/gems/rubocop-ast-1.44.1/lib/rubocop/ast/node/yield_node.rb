# frozen_string_literal: true

module RuboCop
  module AST
    # A node extension for `yield` nodes. This will be used in place of a plain
    # node when the builder constructs the AST, making its methods available
    # to all `yield` nodes within RuboCop.
    class YieldNode < Node
      include ParameterizedNode
      include MethodDispatchNode

      # Custom destructuring method. This can be used to normalize
      # destructuring for different variations of the node.
      #
      # @return [Array] the different parts of the `send` node
      def node_parts
        [nil, :yield, *to_a]
      end

      alias arguments children
    end
  end
end
