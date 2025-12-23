# frozen_string_literal: true

require "forwardable"

module Sidekiq
  class RingBuffer
    include Enumerable
    extend Forwardable
    def_delegators :@buf, :[], :each, :size

    def initialize(size, default = 0)
      @size = size
      @buf = Array.new(size, default)
      @index = 0
    end

    def <<(element)
      @buf[@index % @size] = element
      @index += 1
      element
    end

    def buffer
      @buf
    end

    def reset(default = 0)
      @buf.fill(default)
    end
  end
end
