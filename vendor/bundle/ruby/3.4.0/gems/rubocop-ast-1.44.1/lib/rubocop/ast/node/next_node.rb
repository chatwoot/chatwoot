# frozen_string_literal: true

module RuboCop
  module AST
    # A node extension for `next` nodes. This will be used in place of a
    # plain node when the builder constructs the AST, making its methods
    # available to all `next` nodes within RuboCop.
    class NextNode < Node
      include ParameterizedNode::WrappedArguments
    end
  end
end
