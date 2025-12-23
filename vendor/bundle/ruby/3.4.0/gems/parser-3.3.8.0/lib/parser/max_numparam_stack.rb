# frozen_string_literal: true

module Parser

  # Holds p->max_numparam from parse.y
  #
  # @api private
  class MaxNumparamStack
    attr_reader :stack

    ORDINARY_PARAMS = -1

    def initialize
      @stack = []
    end

    def empty?
      @stack.size == 0
    end

    def has_ordinary_params!
      set(ORDINARY_PARAMS)
    end

    def has_ordinary_params?
      top == ORDINARY_PARAMS
    end

    def has_numparams?
      top && top > 0
    end

    def register(numparam)
      set( [top, numparam].max )
    end

    def top
      @stack.last[:value]
    end

    def push(static:)
      @stack.push(value: 0, static: static)
    end

    def pop
      @stack.pop[:value]
    end

    private

    def set(value)
      @stack.last[:value] = value
    end
  end

end
