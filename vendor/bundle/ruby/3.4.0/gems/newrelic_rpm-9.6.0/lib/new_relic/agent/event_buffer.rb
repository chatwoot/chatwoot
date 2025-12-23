# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

# EventBuffer is intended to be an abstract base class. It should not be
# instantiated directly. Subclasses should define an `append_event` method
# looking something like this:
#
# def append_event(x)
#   <attempt to append>
#   if append_success?
#     return x
#   else
#     return nil
#   end
# end

module NewRelic
  module Agent
    class EventBuffer
      attr_reader :capacity

      def initialize(capacity)
        @capacity = capacity
        @items = []
        @seen = 0
      end

      def reset!
        @items = []
        @seen = 0
      end

      def capacity=(new_capacity)
        @capacity = new_capacity
        old_items = @items
        @items = []
        old_seen = @seen
        old_items.each { |i| append(i) }
        @seen = old_seen
      end

      def append(x)
        @seen += 1
        append_event(x)
      end

      def <<(x)
        append(x)
        self # return self for method chaining
      end

      def full?
        @items.size >= @capacity
      end

      def size
        @items.size
      end

      def note_dropped
        @seen += 1
      end

      def num_seen
        @seen
      end

      def num_dropped
        @seen - @items.size
      end

      def sample_rate
        @seen > 0 ? (size.to_f / @seen) : 0.0
      end

      def to_a
        @items.dup
      end

      def metadata
        {
          :capacity => @capacity,
          :captured => @items.size,
          :seen => @seen
        }
      end
    end
  end
end
