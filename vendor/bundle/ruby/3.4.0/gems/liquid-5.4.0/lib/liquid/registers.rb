# frozen_string_literal: true

module Liquid
  class Registers
    attr_reader :static

    def initialize(registers = {})
      @static = registers.is_a?(Registers) ? registers.static : registers
      @changes = {}
    end

    def []=(key, value)
      @changes[key] = value
    end

    def [](key)
      if @changes.key?(key)
        @changes[key]
      else
        @static[key]
      end
    end

    def delete(key)
      @changes.delete(key)
    end

    UNDEFINED = Object.new

    def fetch(key, default = UNDEFINED, &block)
      if @changes.key?(key)
        @changes.fetch(key)
      elsif default != UNDEFINED
        if block_given?
          @static.fetch(key, &block)
        else
          @static.fetch(key, default)
        end
      else
        @static.fetch(key, &block)
      end
    end

    def key?(key)
      @changes.key?(key) || @static.key?(key)
    end
  end

  # Alias for backwards compatibility
  StaticRegisters = Registers
end
