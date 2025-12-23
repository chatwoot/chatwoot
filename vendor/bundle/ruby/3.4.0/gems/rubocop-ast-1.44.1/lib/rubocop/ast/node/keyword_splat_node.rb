# frozen_string_literal: true

module RuboCop
  module AST
    # A node extension for `kwsplat` and `forwarded_kwrestarg` nodes. This will be used in
    # place of a plain node when the builder constructs the AST, making its methods available to
    # all `kwsplat` and `forwarded_kwrestarg` nodes within RuboCop.
    class KeywordSplatNode < Node
      include HashElementNode

      DOUBLE_SPLAT = '**'
      private_constant :DOUBLE_SPLAT

      # This is used for duck typing with `pair` nodes which also appear as
      # `hash` elements.
      #
      # @return [false]
      def hash_rocket?
        false
      end

      # This is used for duck typing with `pair` nodes which also appear as
      # `hash` elements.
      #
      # @return [false]
      def colon?
        false
      end

      # Returns the operator for the `kwsplat` as a string.
      #
      # @return [String] the double splat operator
      def operator
        DOUBLE_SPLAT
      end

      # Custom destructuring method. This is used to normalize the branches
      # for `pair` and `kwsplat` nodes, to add duck typing to `hash` elements.
      #
      # @return [Array<KeywordSplatNode>] the different parts of the `kwsplat`
      def node_parts
        [self, self]
      end

      # This provides `forwarded_kwrestarg` node to return true to be compatible with `kwsplat` node.
      #
      # @return [true]
      def kwsplat_type?
        true
      end
    end
  end
end
