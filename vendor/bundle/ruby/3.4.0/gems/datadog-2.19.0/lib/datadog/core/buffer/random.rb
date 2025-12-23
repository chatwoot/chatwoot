# frozen_string_literal: true

module Datadog
  module Core
    module Buffer
      # Buffer that accumulates items for a consumer.
      # Consumption can happen from a different thread.

      # Buffer that stores objects. The buffer has a maximum size and when
      # the buffer is full, a random object is discarded.
      class Random
        def initialize(max_size)
          @max_size = max_size
          @items = []
          @closed = false
        end

        # Add a new ``item`` in the local queue. This method doesn't block the execution
        # even if the buffer is full.
        #
        # When the buffer is full, we try to ensure that we are fairly choosing newly
        # pushed items by randomly inserting them into the buffer slots. This discards
        # old items randomly while trying to ensure that recent items are still captured.
        def push(item)
          return if closed?

          full? ? replace!(item) : add!(item)
          item
        end

        # A bulk push alternative to +#push+. Use this method if
        # pushing more than one item for efficiency.
        def concat(items)
          return if closed?

          # Segment items into underflow and overflow
          underflow, overflow = overflow_segments(items)

          # Concatenate items do not exceed capacity.
          add_all!(underflow) unless underflow.nil?

          # Iteratively replace items, to ensure pseudo-random replacement.
          overflow&.each { |item| replace!(item) }
        end

        def unshift(*items)
          # TODO The existing concat implementation does not always append
          # to the end of the buffer - if the buffer is full, a random
          # item is deleted and the new item is added in the position of
          # removed item.
          # Therefore, if we want to preserve the item order, concat
          # would also need to be changed to maintain order.
          # With the existing implementation, the idea is to not move
          # existing items around, which is what sets unshift apart from
          # concat to begin with.
          #
          # Since this method currently delegates to +concat+, it does not
          # have a matching definition in the thread-safe worker.
          concat(items)
        end

        # Stored items are returned and the local buffer is reset.
        def pop
          drain!
        end

        # Return the current number of stored items.
        def length
          @items.length
        end

        # Return if the buffer is empty.
        def empty?
          @items.empty?
        end

        # Closes this buffer, preventing further pushing.
        # Draining is still allowed.
        def close
          @closed = true
        end

        def closed?
          @closed
        end

        protected

        # Segment items into two segments: underflow and overflow.
        # Underflow are items that will fit into buffer.
        # Overflow are items that will exceed capacity, after underflow is added.
        # Returns each array, and nil if there is no underflow/overflow.
        def overflow_segments(items)
          underflow = nil
          overflow = nil

          overflow_size = (@max_size > 0) ? (@items.length + items.length) - @max_size : 0

          if overflow_size > 0
            # Items will overflow
            if overflow_size < items.length
              # Partial overflow
              underflow_end_index = items.length - overflow_size - 1
              underflow = items[0..underflow_end_index]
              overflow = items[(underflow_end_index + 1)..-1]
            else
              # Total overflow
              overflow = items
            end
          else
            # Items do not exceed capacity.
            underflow = items
          end

          [underflow, overflow]
        end

        def full?
          @max_size > 0 && @items.length >= @max_size
        end

        def add_all!(items)
          @items.concat(items)
        end

        def add!(item)
          @items << item
        end

        def replace!(item)
          # Choose random item to be replaced
          replace_index = rand(@items.length)

          # Replace random item
          discarded_item = @items[replace_index]
          @items[replace_index] = item

          # Return discarded item
          discarded_item
        end

        def drain!
          items = @items
          @items = []
          items
        end
      end
    end
  end
end
