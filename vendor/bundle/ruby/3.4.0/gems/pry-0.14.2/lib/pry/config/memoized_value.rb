# frozen_string_literal: true

class Pry
  class Config
    # MemoizedValue is a Proc (block) wrapper. It is meant to be used as a
    # configuration value. Subsequent `#call` calls return the same memoized
    # result.
    #
    # @example
    #   num = 19
    #   value = Pry::Config::MemoizedValue.new { num += 1 }
    #   value.call # => 20
    #   value.call # => 20
    #   value.call # => 20
    #
    # @api private
    # @since v0.13.0
    # @see Pry::Config::LazyValue
    class MemoizedValue
      def initialize(&block)
        @block = block
        @called = false
        @call = nil
      end

      def call
        return @call if @called

        @called = true
        @call = @block.call
      end
    end
  end
end
