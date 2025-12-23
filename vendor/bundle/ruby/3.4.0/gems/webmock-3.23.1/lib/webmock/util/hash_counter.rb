# frozen_string_literal: true

require 'thread'

module WebMock
  module Util
    class HashCounter
      attr_accessor :hash

      def initialize
        self.hash = Hash.new(0)
        @order = {}
        @max = 0
        @lock = ::Mutex.new
      end

      def put(key, num=1)
        @lock.synchronize do
          hash[key] += num
          @order[key] = @max += 1
        end
      end

      def get(key)
        @lock.synchronize do
          hash[key]
        end
      end

      def select(&block)
        return unless block_given?

        @lock.synchronize do
          hash.select(&block)
        end
      end

      def each(&block)
        @order.to_a.sort_by { |a| a[1] }.each do |a|
          yield(a[0], hash[a[0]])
        end
      end
    end
  end
end
