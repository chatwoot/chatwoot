# frozen_string_literal: true

module RuboCop
  module AST
    # A node extension for `dstr` nodes. This will be used
    # in place of a plain node when the builder constructs the AST, making
    # its methods available to all `dstr` nodes within RuboCop.
    class DstrNode < StrNode
      def value
        child_nodes.map do |child|
          child.respond_to?(:value) ? child.value : child.source
        end.join
      end
    end
  end
end
