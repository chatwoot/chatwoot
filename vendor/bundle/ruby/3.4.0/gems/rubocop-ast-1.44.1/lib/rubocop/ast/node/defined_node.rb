# frozen_string_literal: true

module RuboCop
  module AST
    # A node extension for `defined?` nodes. This will be used in place of a
    # plain node when the builder constructs the AST, making its methods
    # available to all `send` nodes within RuboCop.
    class DefinedNode < Node
      include ParameterizedNode
      include MethodDispatchNode

      def node_parts
        [nil, :defined?, *to_a]
      end

      alias arguments children
    end
  end
end
