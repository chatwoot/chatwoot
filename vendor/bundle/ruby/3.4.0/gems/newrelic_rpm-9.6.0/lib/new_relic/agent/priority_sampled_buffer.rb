# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

require 'new_relic/agent/heap'
require 'new_relic/agent/event_buffer'

module NewRelic
  module Agent
    class PrioritySampledBuffer < EventBuffer
      PRIORITY_KEY = 'priority'.freeze

      attr_reader :seen_lifetime, :captured_lifetime

      def initialize(capacity)
        super
        @captured_lifetime = 0
        @seen_lifetime = 0
      end

      def heapify_items_array
        if @items.is_a?(Array)
          @items = Heap.new(@items) { |x| priority_for(x) }
        end
      end

      # expects priority and a block, or an event as a hash with a `priority` key.
      def append(priority: nil, event: nil, &blk)
        increment_seen

        return if @capacity == 0

        if full?
          priority ||= priority_for(event)
          if priority_for(@items[0]) < priority
            heapify_items_array
            incoming = event || yield
            @items[0] = incoming
            @items.fix(0)
            incoming
          end
        else
          @items << (event || yield)
          @captured_lifetime += 1
          @items[-1]
        end
      end

      alias_method :append_event, :append

      def capacity=(new_capacity)
        @capacity = new_capacity
        old_items = @items.to_a
        old_seen = @seen
        reset!
        old_items.each { |i| append(event: i) }
        @seen = old_seen
      end

      def to_a
        @items.to_a.dup
      end

      def decrement_lifetime_counts_by(n)
        @captured_lifetime -= n
        @seen_lifetime -= n
      end

      def sample_rate_lifetime
        @captured_lifetime > 0 ? (@captured_lifetime.to_f / @seen_lifetime) : 0.0
      end

      def metadata
        super.merge!(
          :captured_lifetime => @captured_lifetime,
          :seen_lifetime => @seen_lifetime
        )
      end

      private

      def increment_seen
        @seen += 1
        @seen_lifetime += 1
      end

      def priority_for(event)
        event[0][PRIORITY_KEY]
      end
    end
  end
end
