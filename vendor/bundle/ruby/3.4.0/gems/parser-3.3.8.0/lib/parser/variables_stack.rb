# frozen_string_literal: true

module Parser

  class VariablesStack
    def initialize
      @stack = []
      push
    end

    def empty?
      @stack.empty?
    end

    def push
      @stack << Set.new
    end

    def pop
      @stack.pop
    end

    def reset
      @stack.clear
    end

    def declare(name)
      @stack.last << name.to_sym
    end

    def declared?(name)
      @stack.last.include?(name.to_sym)
    end
  end

end
