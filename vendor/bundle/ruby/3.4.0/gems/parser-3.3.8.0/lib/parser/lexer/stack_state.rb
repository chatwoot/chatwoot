# frozen_string_literal: true

module Parser

  class Lexer::StackState
    def initialize(name)
      @name  = name.freeze
      clear
    end

    def clear
      @stack = 0
    end

    def push(bit)
      bit_value = bit ? 1 : 0
      @stack = (@stack << 1) | bit_value

      bit
    end

    def pop
      bit_value = @stack & 1
      @stack  >>= 1

      bit_value == 1
    end

    def lexpop
      @stack = ((@stack >> 1) | (@stack & 1))
      @stack[0] == 1
    end

    def active?
      @stack[0] == 1
    end

    def empty?
      @stack == 0
    end

    def to_s
      "[#{@stack.to_s(2)} <= #{@name}]"
    end

    alias inspect to_s
  end

end
