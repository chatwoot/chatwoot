# frozen_string_literal: true

module RuboCop
  module AST
    # A node extension for `lvar`, `ivar`, `cvar` and `gvar` nodes.
    # This will be used in place of a plain node when the builder constructs
    # the AST, making its methods available to all assignment nodes within RuboCop.
    class VarNode < Node
      # @return [Symbol] The name of the variable.
      def name
        node_parts[0]
      end
    end
  end
end
