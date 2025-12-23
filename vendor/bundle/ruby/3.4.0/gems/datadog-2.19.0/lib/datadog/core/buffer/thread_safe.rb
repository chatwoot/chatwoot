# frozen_string_literal: true

require_relative 'random'

module Datadog
  module Core
    module Buffer
      # Buffer that stores objects, has a maximum size, and
      # can be safely used concurrently on any environment.
      #
      # This implementation uses a {Mutex} around public methods, incurring
      # overhead in order to ensure thread-safety.
      #
      # This is implementation is recommended for non-CRuby environments.
      # If using CRuby, {Datadog::Core::Buffer::CRuby} is a faster implementation with minimal compromise.
      class ThreadSafe < Random
        def initialize(max_size)
          super

          @mutex = Mutex.new
        end

        # Add a new ``item`` in the local queue. This method doesn't block the execution
        # even if the buffer is full. In that case, a random item is discarded.
        def push(item)
          synchronize { super }
        end

        def concat(items)
          synchronize { super }
        end

        # Return the current number of stored items.
        def length
          synchronize { super }
        end

        # Return if the buffer is empty.
        def empty?
          synchronize { super }
        end

        # Stored items are returned and the local buffer is reset.
        def pop
          synchronize { super }
        end

        def close
          synchronize { super }
        end

        def synchronize(&block)
          @mutex.synchronize(&block)
        end
      end
    end
  end
end
