# frozen_string_literal: true

module RuboCop
  module AST
    # A node extension for `rational` nodes. This will be used in place of a plain
    # node when the builder constructs the AST, making its methods available to
    # all `rational` nodes within RuboCop.
    class RationalNode < Node
      include BasicLiteralNode
      include NumericNode
    end
  end
end
