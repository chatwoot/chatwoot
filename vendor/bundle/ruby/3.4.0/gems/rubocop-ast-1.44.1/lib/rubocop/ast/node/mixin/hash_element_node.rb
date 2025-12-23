# frozen_string_literal: true

module RuboCop
  module AST
    # Common functionality for nodes that can be used as hash elements:
    # `pair`, `kwsplat`
    module HashElementNode
      # Returns the key of this `hash` element.
      #
      # @note For keyword splats, this returns the whole node
      #
      # @return [Node] the key of the hash element
      def key
        node_parts[0]
      end

      # Returns the value of this `hash` element.
      #
      # @note For keyword splats, this returns the whole node
      #
      # @return [Node] the value of the hash element
      def value
        node_parts[1]
      end

      # Checks whether this `hash` element is on the same line as `other`.
      #
      # @note A multiline element is considered to be on the same line if it
      #       shares any of its lines with `other`
      #
      # @return [Boolean] whether this element is on the same line as `other`
      def same_line?(other)
        loc.last_line == other.loc.line || loc.line == other.loc.last_line
      end

      # Returns the delta between this pair's key and the argument pair's.
      #
      # @note Keys on the same line always return a delta of 0
      # @note Keyword splats always return a delta of 0 for right alignment
      #
      # @param [Symbol] alignment whether to check the left or right side
      # @return [Integer] the delta between the two keys
      def key_delta(other, alignment = :left)
        HashElementDelta.new(self, other).key_delta(alignment)
      end

      # Returns the delta between this element's value and the argument's.
      #
      # @note Keyword splats always return a delta of 0
      #
      # @return [Integer] the delta between the two values
      def value_delta(other)
        HashElementDelta.new(self, other).value_delta
      end

      # Returns the delta between this element's delimiter and the argument's.
      #
      # @note Pairs with different delimiter styles return a delta of 0
      #
      # @return [Integer] the delta between the two delimiters
      def delimiter_delta(other)
        HashElementDelta.new(self, other).delimiter_delta
      end

      # A helper class for comparing the positions of different parts of a
      # `pair` node.
      class HashElementDelta
        def initialize(first, second)
          @first = first
          @second = second

          raise ArgumentError unless valid_argument_types?
        end

        def key_delta(alignment = :left)
          return 0 if first.same_line?(second)
          return 0 if keyword_splat? && alignment == :right

          delta(first.key.loc, second.key.loc, alignment)
        end

        def value_delta
          return 0 if first.same_line?(second)
          return 0 if keyword_splat?

          delta(first.value.loc, second.value.loc)
        end

        def delimiter_delta
          return 0 if first.same_line?(second)
          return 0 if first.delimiter != second.delimiter

          delta(first.loc.operator, second.loc.operator)
        end

        private

        attr_reader :first, :second

        def valid_argument_types?
          [first, second].all? do |argument|
            # rubocop:disable InternalAffairs/NodeTypeMultiplePredicates
            argument.pair_type? || argument.kwsplat_type?
            # rubocop:enable InternalAffairs/NodeTypeMultiplePredicates
          end
        end

        def delta(first, second, alignment = :left)
          case alignment
          when :left
            first.column - second.column
          when :right
            first.last_column - second.last_column
          else
            0
          end
        end

        def keyword_splat?
          [first, second].any?(&:kwsplat_type?)
        end
      end

      private_constant :HashElementDelta
    end
  end
end
