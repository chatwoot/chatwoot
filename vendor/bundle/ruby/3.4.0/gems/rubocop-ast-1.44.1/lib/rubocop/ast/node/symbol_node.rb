# frozen_string_literal: true

module RuboCop
  module AST
    # A node extension for `sym` nodes. This will be used in  place of a
    # plain node when the builder constructs the AST, making its methods
    # available to all `sym` nodes within RuboCop.
    class SymbolNode < Node
      include BasicLiteralNode
    end
  end
end
