# frozen_string_literal: true

module Parser
  # Stack that holds names of current arguments,
  # i.e. while parsing
  #   def m1(a = (def m2(b = def m3(c = 1); end); end)); end
  #                                   ^
  # stack is [:a, :b, :c]
  #
  # Emulates `p->cur_arg` in MRI's parse.y
  #
  # @api private
  #
  class CurrentArgStack
    attr_reader :stack

    def initialize
      @stack = []
      freeze
    end

    def empty?
      @stack.size == 0
    end

    def push(value)
      @stack << value
    end

    def set(value)
      @stack[@stack.length - 1] = value
    end

    def pop
      @stack.pop
    end

    def reset
      @stack.clear
    end

    def top
      @stack.last
    end
  end
end
