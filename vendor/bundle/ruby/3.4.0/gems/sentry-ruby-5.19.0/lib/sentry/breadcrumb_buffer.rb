# frozen_string_literal: true

require "sentry/breadcrumb"

module Sentry
  class BreadcrumbBuffer
    DEFAULT_SIZE = 100
    include Enumerable

    # @return [Array]
    attr_accessor :buffer

    # @param size [Integer, nil] If it's not provided, it'll fallback to DEFAULT_SIZE
    def initialize(size = nil)
      @buffer = Array.new(size || DEFAULT_SIZE)
    end

    # @param crumb [Breadcrumb]
    # @return [void]
    def record(crumb)
      yield(crumb) if block_given?
      @buffer.slice!(0)
      @buffer << crumb
    end

    # @return [Array]
    def members
      @buffer.compact
    end

    # Returns the last breadcrumb stored in the buffer. If the buffer it's empty, it returns nil.
    # @return [Breadcrumb, nil]
    def peek
      members.last
    end

    # Iterates through all breadcrumbs.
    # @param block [Proc]
    # @yieldparam crumb [Breadcrumb]
    # @return [Array]
    def each(&block)
      members.each(&block)
    end

    # @return [Boolean]
    def empty?
      members.none?
    end

    # @return [Hash]
    def to_hash
      {
        values: members.map(&:to_hash)
      }
    end

    # @return [BreadcrumbBuffer]
    def dup
      copy = super
      copy.buffer = buffer.deep_dup
      copy
    end
  end
end
