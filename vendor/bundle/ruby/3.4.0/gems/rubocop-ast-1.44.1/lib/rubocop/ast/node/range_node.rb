# frozen_string_literal: true

module RuboCop
  module AST
    # A node extension for `irange` and `erange` nodes. This will be used in
    # place of a plain node when the builder constructs the AST, making its
    # methods available to all `irange` and `erange` nodes within RuboCop.
    class RangeNode < Node
      def begin
        node_parts[0]
      end

      def end
        node_parts[1]
      end
    end
  end
end
