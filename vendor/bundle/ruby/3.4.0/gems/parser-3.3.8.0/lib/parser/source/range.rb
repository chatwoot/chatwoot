# frozen_string_literal: true

module Parser
  module Source

    ##
    # A range of characters in a particular source buffer.
    #
    # The range is always exclusive, i.e. a range with `begin_pos` of 3 and
    # `end_pos` of 5 will contain the following characters:
    #
    #     example
    #        ^^
    #
    # @!attribute [r] source_buffer
    #  @return [Parser::Source::Buffer]
    #
    # @!attribute [r] begin_pos
    #  @return [Integer] index of the first character in the range
    #
    # @!attribute [r] end_pos
    #  @return [Integer] index of the character after the last character in the range
    #
    # @api public
    #
    class Range
      include Comparable

      attr_reader :source_buffer
      attr_reader :begin_pos, :end_pos

      ##
      # @param [Buffer]  source_buffer
      # @param [Integer] begin_pos
      # @param [Integer] end_pos
      #
      def initialize(source_buffer, begin_pos, end_pos)
        if end_pos < begin_pos
          raise ArgumentError, 'Parser::Source::Range: end_pos must not be less than begin_pos'
        end
        if source_buffer.nil?
          raise ArgumentError, 'Parser::Source::Range: source_buffer must not be nil'
        end

        @source_buffer       = source_buffer
        @begin_pos, @end_pos = begin_pos, end_pos

        freeze
      end

      ##
      # @return [Range] a zero-length range located just before the beginning
      #   of this range.
      #
      def begin
        with(end_pos: @begin_pos)
      end

      ##
      # @return [Range] a zero-length range located just after the end
      #   of this range.
      #
      def end
        with(begin_pos: @end_pos)
      end

      ##
      # @return [Integer] amount of characters included in this range.
      #
      def size
        @end_pos - @begin_pos
      end

      alias length size

      ##
      # Line number of the beginning of this range. By default, the first line
      # of a buffer is 1; as such, line numbers are most commonly one-based.
      #
      # @see Buffer
      # @return [Integer] line number of the beginning of this range.
      #
      def line
        @source_buffer.line_for_position(@begin_pos)
      end

      alias_method :first_line, :line

      ##
      # @return [Integer] zero-based column number of the beginning of this range.
      #
      def column
        @source_buffer.column_for_position(@begin_pos)
      end

      ##
      # @return [Integer] line number of the end of this range.
      #
      def last_line
        @source_buffer.line_for_position(@end_pos)
      end

      ##
      # @return [Integer] zero-based column number of the end of this range.
      #
      def last_column
        @source_buffer.column_for_position(@end_pos)
      end

      ##
      # @return [::Range] a range of columns spanned by this range.
      # @raise RangeError
      #
      def column_range
        if line != last_line
          raise RangeError, "#{self.inspect} spans more than one line"
        end

        column...last_column
      end

      ##
      # @return [String] a line of source code containing the beginning of this range.
      #
      def source_line
        @source_buffer.source_line(line)
      end

      ##
      # @return [String] all source code covered by this range.
      #
      def source
        @source_buffer.slice(@begin_pos, @end_pos - @begin_pos)
      end

      ##
      # `is?` provides a concise way to compare the source corresponding to this range.
      # For example, `r.source == '(' || r.source == 'begin'` is equivalent to
      # `r.is?('(', 'begin')`.
      #
      def is?(*what)
        what.include?(source)
      end

      ##
      # @return [Array<Integer>] a set of character indexes contained in this range.
      #
      def to_a
        (@begin_pos...@end_pos).to_a
      end

      ##
      # @return [Range] a Ruby range with the same `begin_pos` and `end_pos`
      #
      def to_range
        self.begin_pos...self.end_pos
      end

      ##
      # Composes a GNU/Clang-style string representation of the beginning of this
      # range.
      #
      # For example, for the following range in file `foo.rb`,
      #
      #     def foo
      #         ^^^
      #
      # `to_s` will return `foo.rb:1:5`.
      # Note that the column index is one-based.
      #
      # @return [String]
      #
      def to_s
        line, column = @source_buffer.decompose_position(@begin_pos)

        [@source_buffer.name, line, column + 1].join(':')
      end

      ##
      # @param [Hash] Endpoint(s) to change, any combination of :begin_pos or :end_pos
      # @return [Range] the same range as this range but with the given end point(s) changed
      # to the given value(s).
      #
      def with(begin_pos: @begin_pos, end_pos: @end_pos)
        Range.new(@source_buffer, begin_pos, end_pos)
      end

      ##
      # @param [Hash] Endpoint(s) to change, any combination of :begin_pos or :end_pos
      # @return [Range] the same range as this range but with the given end point(s) adjusted
      # by the given amount(s)
      #
      def adjust(begin_pos: 0, end_pos: 0)
        Range.new(@source_buffer, @begin_pos + begin_pos, @end_pos + end_pos)
      end

      ##
      # @param [Integer] new_size
      # @return [Range] a range beginning at the same point as this range and length `new_size`.
      #
      def resize(new_size)
        with(end_pos: @begin_pos + new_size)
      end

      ##
      # @param [Range] other
      # @return [Range] smallest possible range spanning both this range and `other`.
      #
      def join(other)
        Range.new(@source_buffer,
            [@begin_pos, other.begin_pos].min,
            [@end_pos,   other.end_pos].max)
      end

      ##
      # @param [Range] other
      # @return [Range] overlapping region of this range and `other`, or `nil`
      #   if they do not overlap
      #
      def intersect(other)
        unless disjoint?(other)
          Range.new(@source_buffer,
            [@begin_pos, other.begin_pos].max,
            [@end_pos,   other.end_pos].min)
        end
      end

      ##
      # Return `true` iff this range and `other` are disjoint.
      #
      # Two ranges must be one and only one of ==, disjoint?, contains?, contained? or crossing?
      #
      # @param [Range] other
      # @return [Boolean]
      #
      def disjoint?(other)
        if empty? && other.empty?
          @begin_pos != other.begin_pos
        else
          @begin_pos >= other.end_pos || other.begin_pos >= @end_pos
        end
      end

      ##
      # Return `true` iff this range is not disjoint from `other`.
      #
      # @param [Range] other
      # @return [Boolean] `true` if this range and `other` overlap
      #
      def overlaps?(other)
        !disjoint?(other)
      end

      ##
      # Returns true iff this range contains (strictly) `other`.
      #
      # Two ranges must be one and only one of ==, disjoint?, contains?, contained? or crossing?
      #
      # @param [Range] other
      # @return [Boolean]
      #
      def contains?(other)
        (other.begin_pos <=> @begin_pos) + (@end_pos <=> other.end_pos) >= (other.empty? ? 2 : 1)
      end

      ##
      # Return `other.contains?(self)`
      #
      # Two ranges must be one and only one of ==, disjoint?, contains?, contained? or crossing?
      #
      # @param [Range] other
      # @return [Boolean]
      #
      def contained?(other)
        other.contains?(self)
      end

      ##
      # Returns true iff both ranges intersect and also have different elements from one another.
      #
      # Two ranges must be one and only one of ==, disjoint?, contains?, contained? or crossing?
      #
      # @param [Range] other
      # @return [Boolean]
      #
      def crossing?(other)
        return false unless overlaps?(other)
        (@begin_pos <=> other.begin_pos) * (@end_pos <=> other.end_pos) == 1
      end

      ##
      # Checks if a range is empty; if it contains no characters
      # @return [Boolean]
      def empty?
        @begin_pos == @end_pos
      end

      ##
      # Compare ranges, first by begin_pos, then by end_pos.
      #
      def <=>(other)
        return nil unless other.is_a?(::Parser::Source::Range) &&
          @source_buffer == other.source_buffer
        (@begin_pos <=> other.begin_pos).nonzero? ||
        (@end_pos <=> other.end_pos)
      end

      alias_method :eql?, :==

      ##
      # Support for Ranges be used in as Hash indices and in Sets.
      #
      def hash
        [@source_buffer, @begin_pos, @end_pos].hash
      end

      ##
      # @return [String] a human-readable representation of this range.
      #
      def inspect
        "#<Parser::Source::Range #{@source_buffer.name} #{@begin_pos}...#{@end_pos}>"
      end
    end

  end
end
