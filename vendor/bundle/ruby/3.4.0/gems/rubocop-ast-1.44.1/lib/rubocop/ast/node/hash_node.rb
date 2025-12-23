# frozen_string_literal: true

module RuboCop
  module AST
    # A node extension for `hash` nodes. This will be used in place of a plain
    # node when the builder constructs the AST, making its methods available
    # to all `hash` nodes within RuboCop.
    class HashNode < Node
      # Returns an array of all the key value pairs in the `hash` literal.
      #
      # @note this may be different from children as `kwsplat` nodes are
      # ignored.
      #
      # @return [Array<PairNode>] an array of `pair` nodes
      def pairs
        each_pair.to_a
      end

      # Checks whether the `hash` node contains any `pair`- or `kwsplat` nodes.
      #
      # @return[Boolean] whether the `hash` is empty
      def empty?
        children.empty?
      end

      # Calls the given block for each `pair` node in the `hash` literal.
      # If no block is given, an `Enumerator` is returned.
      #
      # @note `kwsplat` nodes are ignored.
      #
      # @return [self] if a block is given
      # @return [Enumerator] if no block is given
      def each_pair
        return each_child_node(:pair).to_enum unless block_given?

        each_child_node(:pair) do |pair|
          yield(*pair)
        end

        self
      end

      # Returns an array of all the keys in the `hash` literal.
      #
      # @note `kwsplat` nodes are ignored.
      #
      # @return [Array<Node>] an array of keys in the `hash` literal
      def keys
        each_key.to_a
      end

      # Calls the given block for each `key` node in the `hash` literal.
      # If no block is given, an `Enumerator` is returned.
      #
      # @note `kwsplat` nodes are ignored.
      #
      # @return [self] if a block is given
      # @return [Enumerator] if no block is given
      def each_key(&block)
        return pairs.map(&:key).to_enum unless block

        pairs.map(&:key).each(&block)

        self
      end

      # Returns an array of all the values in the `hash` literal.
      #
      # @note `kwsplat` nodes are ignored.
      #
      # @return [Array<Node>] an array of values in the `hash` literal
      def values
        each_pair.map(&:value)
      end

      # Calls the given block for each `value` node in the `hash` literal.
      # If no block is given, an `Enumerator` is returned.
      #
      # @note `kwsplat` nodes are ignored.
      #
      # @return [self] if a block is given
      # @return [Enumerator] if no block is given
      def each_value(&block)
        return pairs.map(&:value).to_enum unless block

        pairs.map(&:value).each(&block)

        self
      end

      # Checks whether any of the key value pairs in the `hash` literal are on
      # the same line.
      #
      # @note A multiline `pair` is considered to be on the same line if it
      #       shares any of its lines with another `pair`
      #
      # @note `kwsplat` nodes are ignored.
      #
      # @return [Boolean] whether any `pair` nodes are on the same line
      def pairs_on_same_line?
        pairs.each_cons(2).any? { |first, second| first.same_line?(second) }
      end

      # Checks whether this `hash` uses a mix of hash rocket and colon
      # delimiters for its pairs.
      #
      # @note `kwsplat` nodes are ignored.
      #
      # @return [Boolean] whether the `hash` uses mixed delimiters
      def mixed_delimiters?
        pairs.map(&:delimiter).uniq.size > 1
      end

      # Checks whether the `hash` literal is delimited by curly braces.
      #
      # @return [Boolean] whether the `hash` literal is enclosed in braces
      def braces?
        loc_is?(:end, '}')
      end
    end
  end
end
