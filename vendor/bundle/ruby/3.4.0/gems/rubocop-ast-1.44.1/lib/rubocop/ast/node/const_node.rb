# frozen_string_literal: true

module RuboCop
  module AST
    # A node extension for `const` nodes.
    class ConstNode < Node
      include ConstantNode
    end
  end
end
