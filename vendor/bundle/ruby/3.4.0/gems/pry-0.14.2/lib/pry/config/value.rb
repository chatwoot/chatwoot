# frozen_string_literal: true

class Pry
  class Config
    # Value holds a value for the given attribute and decides how it should
    # be read. Procs get called, other values are returned as is.
    #
    # @since v0.13.0
    # @api private
    class Value
      def initialize(value)
        @value = value
      end

      def call
        unless [Config::MemoizedValue, Config::LazyValue].include?(@value.class)
          return @value
        end

        @value.call
      end
    end
  end
end
