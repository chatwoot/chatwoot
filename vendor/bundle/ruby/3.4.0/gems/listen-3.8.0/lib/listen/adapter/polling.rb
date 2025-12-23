# frozen_string_literal: true

module Listen
  module Adapter
    # Polling Adapter that works cross-platform and
    # has no dependencies. This is the adapter that
    # uses the most CPU processing power and has higher
    # file IO than the other implementations.
    #
    class Polling < Base
      OS_REGEXP = //.freeze # match every OS

      DEFAULTS = { latency: 1.0, wait_for_delay: 0.05 }.freeze

      private

      def _configure(_, &callback)
        @polling_callbacks ||= []
        @polling_callbacks << callback
      end

      def _run
        loop do
          start = MonotonicTime.now
          @polling_callbacks.each do |callback|
            callback.call(nil)
            if (nap_time = options.latency - (MonotonicTime.now - start)) > 0
              # TODO: warn if nap_time is negative (polling too slow)
              sleep(nap_time)
            end
          end
        end
      end

      def _process_event(dir, _)
        _queue_change(:dir, dir, '.', recursive: true)
      end
    end
  end
end
