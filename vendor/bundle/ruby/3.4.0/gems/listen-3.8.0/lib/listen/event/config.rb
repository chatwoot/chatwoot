# frozen_string_literal: true

module Listen
  module Event
    class Config
      attr_reader :listener, :event_queue, :min_delay_between_events

      def initialize(
        listener,
        event_queue,
        queue_optimizer,
        wait_for_delay,
        &block
      )

        @listener = listener
        @event_queue = event_queue
        @queue_optimizer = queue_optimizer
        @min_delay_between_events = wait_for_delay
        @block = block
      end

      def sleep(seconds)
        Kernel.sleep(seconds)
      end

      def call(*args)
        @block&.call(*args)
      end

      def callable?
        @block
      end

      def optimize_changes(changes)
        @queue_optimizer.smoosh_changes(changes)
      end
    end
  end
end
