# frozen_string_literal: true

require 'forwardable'

module Datadog
  module AppSec
    module APISecurity
      # An LRU (Least Recently Used) cache implementation that relies on the
      # Ruby 1.9+ `Hash` implementation that guarantees insertion order.
      #
      # WARNING: This implementation is NOT thread-safe and should be used
      #          in a single-threaded context.
      class LRUCache
        extend Forwardable

        def_delegators :@store, :clear, :empty?

        def initialize(max_size)
          raise ArgumentError, 'max_size must be an Integer' unless max_size.is_a?(Integer)
          raise ArgumentError, 'max_size must be greater than 0' if max_size <= 0

          @max_size = max_size
          @store = {}
        end

        # NOTE: Accessing a key moves it to the end of the list.
        def [](key)
          if (entry = @store.delete(key))
            @store[key] = entry
          end
        end

        def store(key, value)
          return @store[key] = value if @store.delete(key)

          # NOTE: evict the oldest entry if store reached the maximum allowed size
          @store.shift if @store.size >= @max_size
          @store[key] = value
        end

        # NOTE: If the key exists, it's moved to the end of the list and
        #       if does not, the given block will be executed and the result
        #       will be stored (which will add it to the end of the list).
        def fetch_or_store(key)
          if (entry = @store.delete(key))
            return @store[key] = entry
          end

          # NOTE: evict the oldest entry if store reached the maximum allowed size
          @store.shift if @store.size >= @max_size
          @store[key] = yield
        end
      end
    end
  end
end
