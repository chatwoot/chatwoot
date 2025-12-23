# frozen_string_literal: true

require_relative 'random'

module Datadog
  module Core
    module Buffer
      # Buffer that stores objects, has a maximum size, and
      # can be safely used concurrently with CRuby.
      #
      # Because singular +Array+ operations are thread-safe in CRuby,
      # we can implement the buffer without an explicit lock,
      # while making the compromise of allowing the buffer to go
      # over its maximum limit under extreme circumstances.
      #
      # On the following scenario:
      # * 4.5 million spans/second.
      # * Pushed into a single CRubyTraceBuffer from 1000 threads.
      #
      # This implementation allocates less memory and is faster
      # than {Datadog::Core::Buffer::ThreadSafe}.
      #
      # @see spec/datadog/benchmark/buffer_benchmark_spec.rb Buffer benchmarks
      # @see https://github.com/ruby-concurrency/concurrent-ruby/blob/c1114a0c6891d9634f019f1f9fe58dcae8658964/lib/concurrent-ruby/concurrent/array.rb#L23-L27
      class CRuby < Random
        # A very large number to allow us to effectively
        # drop all items when invoking `slice!(i, FIXNUM_MAX)`.
        FIXNUM_MAX = (1 << 62) - 1

        # Add a new ``item`` in the local queue. This method doesn't block the execution
        # even if the buffer is full. In that case, a random item is discarded.
        def replace!(item)
          # Ensure buffer stays within +max_size+ items.
          # This can happen when there's concurrent modification
          # between a call the check in `full?` and the `add!` call in
          # `full? ? replace!(item) : add!(item)`.
          #
          # We can still have `@items.size > @max_size` for a short period of
          # time, but we will always try to correct it here.
          #
          # `slice!` is performed before `delete_at` & `<<` to avoid always
          # removing the item that was just inserted.
          #
          # DEV: `slice!` with two integer arguments is ~10% faster than
          # `slice!` with a {Range} argument.
          @items.slice!(@max_size, FIXNUM_MAX)

          # We should replace a random item with the new one
          replace_index = rand(@max_size)
          @items[replace_index] = item
        end
      end
    end
  end
end
