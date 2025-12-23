# frozen_string_literal: true

module Parser
  module Source

    ##
    # @api private
    #
    class Rewriter::Action
      include Comparable

      attr_reader :range, :replacement, :allow_multiple_insertions, :order
      alias_method :allow_multiple_insertions?, :allow_multiple_insertions

      def initialize(range, replacement='', allow_multiple_insertions = false, order = 0)
        @range = range
        @replacement = replacement
        @allow_multiple_insertions = allow_multiple_insertions
        @order = order

        freeze
      end

      def <=>(other)
        result = range.begin_pos <=> other.range.begin_pos
        return result unless result.zero?
        order <=> other.order
      end

      def to_s
        if @range.length == 0 && @replacement.empty?
          'do nothing'
        elsif @range.length == 0
          "insert #{@replacement.inspect}"
        elsif @replacement.empty?
          "remove #{@range.length} character(s)"
        else
          "replace #{@range.length} character(s) with #{@replacement.inspect}"
        end
      end
    end

  end
end
