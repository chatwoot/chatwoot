module SassListen
  module Event
    class Processor
      def initialize(config, reasons)
        @config = config
        @reasons = reasons
        _reset_no_unprocessed_events
      end

      # TODO: implement this properly instead of checking the state at arbitrary
      # points in time
      def loop_for(latency)
        @latency = latency

        loop do
          _wait_until_events
          _wait_until_events_calm_down
          _wait_until_no_longer_paused
          _process_changes
        end
      rescue Stopped
        SassListen::Logger.debug('Processing stopped')
      end

      private

      class Stopped < RuntimeError
      end

      def _wait_until_events_calm_down
        loop do
          now = _timestamp

          # Assure there's at least latency between callbacks to allow
          # for accumulating changes
          diff = _deadline - now
          break if diff <= 0

          # give events a bit of time to accumulate so they can be
          # compressed/optimized
          _sleep(:waiting_until_latency, diff)
        end
      end

      def _wait_until_no_longer_paused
        # TODO: may not be a good idea?
        _sleep(:waiting_for_unpause) while config.paused?
      end

      def _check_stopped
        return unless config.stopped?

        _flush_wakeup_reasons
        raise Stopped
      end

      def _sleep(_local_reason, *args)
        _check_stopped
        sleep_duration = config.sleep(*args)
        _check_stopped

        _flush_wakeup_reasons do |reason|
          next unless reason == :event
          _remember_time_of_first_unprocessed_event unless config.paused?
        end

        sleep_duration
      end

      def _remember_time_of_first_unprocessed_event
        @first_unprocessed_event_time ||= _timestamp
      end

      def _reset_no_unprocessed_events
        @first_unprocessed_event_time = nil
      end

      def _deadline
        @first_unprocessed_event_time + @latency
      end

      def _wait_until_events
        # TODO: long sleep may not be a good idea?
        _sleep(:waiting_for_events) while config.event_queue.empty?
        @first_unprocessed_event_time ||= _timestamp
      end

      def _flush_wakeup_reasons
        reasons = @reasons
        until reasons.empty?
          reason = reasons.pop
          yield reason if block_given?
        end
      end

      def _timestamp
        config.timestamp
      end

      # for easier testing without sleep loop
      def _process_changes
        _reset_no_unprocessed_events

        changes = []
        changes << config.event_queue.pop until config.event_queue.empty?

        callable = config.callable?
        return unless callable

        hash = config.optimize_changes(changes)
        result = [hash[:modified], hash[:added], hash[:removed]]
        return if result.all?(&:empty?)

        block_start = _timestamp
        config.call(*result)
        SassListen::Logger.debug "Callback took #{_timestamp - block_start} sec"
      end

      attr_reader :config
    end
  end
end
