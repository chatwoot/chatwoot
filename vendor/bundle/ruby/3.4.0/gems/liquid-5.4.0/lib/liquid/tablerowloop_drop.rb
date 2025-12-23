# frozen_string_literal: true

module Liquid
  # @liquid_public_docs
  # @liquid_type object
  # @liquid_name tablerowloop
  # @liquid_summary
  #   Information about a parent [`tablerow` loop](/api/liquid/tags#tablerow).
  class TablerowloopDrop < Drop
    def initialize(length, cols)
      @length = length
      @row    = 1
      @col    = 1
      @cols   = cols
      @index  = 0
    end

    # @liquid_public_docs
    # @liquid_summary
    #   The total number of iterations in the loop.
    # @liquid_return [number]
    attr_reader :length

    # @liquid_public_docs
    # @liquid_summary
    #   The 1-based index of the current column.
    # @liquid_return [number]
    attr_reader :col

    # @liquid_public_docs
    # @liquid_summary
    #   The 1-based index of current row.
    # @liquid_return [number]
    attr_reader :row

    # @liquid_public_docs
    # @liquid_summary
    #   The 1-based index of the current iteration.
    # @liquid_return [number]
    def index
      @index + 1
    end

    # @liquid_public_docs
    # @liquid_summary
    #   The 0-based index of the current iteration.
    # @liquid_return [number]
    def index0
      @index
    end

    # @liquid_public_docs
    # @liquid_summary
    #   The 0-based index of the current column.
    # @liquid_return [number]
    def col0
      @col - 1
    end

    # @liquid_public_docs
    # @liquid_summary
    #   The 1-based index of the current iteration, in reverse order.
    # @liquid_return [number]
    def rindex
      @length - @index
    end

    # @liquid_public_docs
    # @liquid_summary
    #   The 0-based index of the current iteration, in reverse order.
    # @liquid_return [number]
    def rindex0
      @length - @index - 1
    end

    # @liquid_public_docs
    # @liquid_summary
    #   Returns `true` if the current iteration is the first. Returns `false` if not.
    # @liquid_return [boolean]
    def first
      @index == 0
    end

    # @liquid_public_docs
    # @liquid_summary
    #   Returns `true` if the current iteration is the last. Returns `false` if not.
    # @liquid_return [boolean]
    def last
      @index == @length - 1
    end

    # @liquid_public_docs
    # @liquid_summary
    #   Returns `true` if the current column is the first in the row. Returns `false` if not.
    # @liquid_return [boolean]
    def col_first
      @col == 1
    end

    # @liquid_public_docs
    # @liquid_summary
    #   Returns `true` if the current column is the last in the row. Returns `false` if not.
    # @liquid_return [boolean]
    def col_last
      @col == @cols
    end

    protected

    def increment!
      @index += 1

      if @col == @cols
        @col = 1
        @row += 1
      else
        @col += 1
      end
    end
  end
end
