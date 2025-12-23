# frozen_string_literal: true

require_relative 'event'

require_relative '../utils/only_once_successful'
require_relative '../workers/polling'
require_relative '../workers/queue'

module Datadog
  module Core
    module Telemetry
      # Accumulates events and sends them to the API at a regular interval, including heartbeat event.
      class Worker
        include Core::Workers::Queue
        include Core::Workers::Polling

        DEFAULT_BUFFER_MAX_SIZE = 1000
        APP_STARTED_EVENT_RETRIES = 10

        def initialize(
          heartbeat_interval_seconds:,
          metrics_aggregation_interval_seconds:,
          emitter:,
          metrics_manager:,
          dependency_collection:,
          logger:,
          enabled: true,
          shutdown_timeout: Workers::Polling::DEFAULT_SHUTDOWN_TIMEOUT,
          buffer_size: DEFAULT_BUFFER_MAX_SIZE
        )
          @emitter = emitter
          @metrics_manager = metrics_manager
          @dependency_collection = dependency_collection
          @logger = logger

          @ticks_per_heartbeat = (heartbeat_interval_seconds / metrics_aggregation_interval_seconds).to_i
          @current_ticks = 0

          # Workers::Polling settings
          self.enabled = enabled
          # Workers::IntervalLoop settings
          self.loop_base_interval = metrics_aggregation_interval_seconds
          self.fork_policy = Core::Workers::Async::Thread::FORK_POLICY_STOP

          @shutdown_timeout = shutdown_timeout
          @buffer_size = buffer_size

          self.buffer = buffer_klass.new(@buffer_size)

          @initial_event_once = Utils::OnlyOnceSuccessful.new(APP_STARTED_EVENT_RETRIES)
        end

        attr_reader :logger
        attr_reader :initial_event_once
        attr_reader :initial_event

        # Returns true if worker thread is successfully started,
        # false if worker thread was not started but telemetry is enabled,
        # nil if telemetry is disabled.
        def start(initial_event)
          return if !enabled? || forked?

          @initial_event = initial_event

          # starts async worker
          # perform should return true if thread was actually started,
          # false otherwise
          perform
        end

        def stop(force_stop = false, timeout = @shutdown_timeout)
          buffer.close if running?

          super
        end

        # Returns true if event was enqueued, nil if not.
        # While returning false may seem more reasonable, the only reason
        # for not enqueueing event (presently) is that telemetry is disabled
        # altogether, and in this case other methods return nil.
        def enqueue(event)
          return if !enabled? || forked?

          buffer.push(event)
          true
        end

        def sent_initial_event?
          initial_event_once.success?
        end

        def failed_initial_event?
          initial_event_once.failed?
        end

        def need_initial_event?
          !sent_initial_event? && !failed_initial_event?
        end

        # Wait for the worker to send out all events that have already
        # been queued, up to 15 seconds. Returns whether all events have
        # been flushed.
        #
        # @api private
        def flush
          return true unless enabled? || !run_loop?

          started = Utils::Time.get_time
          loop do
            # The AppStarted event is triggered by the worker itself,
            # from the worker thread. As such the main thread has no way
            # to delay itself until that event is queued and we need some
            # way to wait until that event is sent out to assert on it in
            # the test suite. Check the run once flag which *should*
            # indicate the event has been queued (at which point our queue
            # depth check should waint until it's sent).
            # This is still a hack because the flag can be overridden
            # either way with or without the event being sent out.
            # Note that if the AppStarted sending fails, this check
            # will return false and flushing will be blocked until the
            # 15 second timeout.
            # Note that the first wait interval between telemetry event
            # sending is 10 seconds, the timeout needs to be strictly
            # greater than that.
            return true if buffer.empty? && !in_iteration? && sent_initial_event?

            sleep 0.5

            return false if Utils::Time.get_time - started > 15
          end
        end

        private

        def perform(*events)
          return if !enabled? || forked?

          if need_initial_event?
            started!
            unless sent_initial_event?
              # We still haven't succeeded in sending the started event,
              # which will make flush_events do nothing - but the events
              # given to us as the parameter have already been removed
              # from the queue.
              # Put the events back to the front of the queue to not
              # lose them.
              buffer.unshift(*events)
              return
            end
          end

          metric_events = @metrics_manager.flush!
          events = [] if events.nil?
          events += metric_events
          if events.any?
            flush_events(events)
          end

          @current_ticks += 1
          return if @current_ticks < @ticks_per_heartbeat

          @current_ticks = 0
          heartbeat!
        end

        def flush_events(events)
          events = deduplicate_logs(events)

          logger.debug { "Sending #{events&.count} telemetry events" }
          send_event(Event::MessageBatch.new(events))
        end

        def heartbeat!
          return if !enabled? || !sent_initial_event?

          send_event(Event::AppHeartbeat.new)
        end

        def started!
          return unless enabled?

          initial_event_once.run do
            res = send_event(initial_event)

            if res.ok?
              logger.debug { "Telemetry initial event (#{initial_event.type}) is successfully sent" }

              # TODO Dependencies loaded event should probably check for new
              # dependencies and send the new ones.
              # System tests demand only one instance of this event per
              # dependency.
              send_event(Event::AppDependenciesLoaded.new) if @dependency_collection && initial_event.class.eql?(Telemetry::Event::AppStarted) # standard:disable Style/ClassEqualityComparison:

              true
            else
              logger.debug("Error sending telemetry initial event (#{initial_event.type}), retry after heartbeat interval...")
              false
            end
          end

          if failed_initial_event?
            logger.debug { "Telemetry initial event (#{initial_event.type}) exhausted retries, disabling telemetry worker" }
            disable!
          end
        end

        def send_event(event)
          res = @emitter.request(event)

          disable_on_not_found!(res)

          res
        end

        def dequeue
          buffer.pop
        end

        def work_pending?
          run_loop? || !buffer.empty?
        end

        def buffer_klass
          if Core::Environment::Ext::RUBY_ENGINE == 'ruby'
            Core::Buffer::CRuby
          else
            Core::Buffer::ThreadSafe
          end
        end

        def disable!
          self.enabled = false
          @metrics_manager.disable!
        end

        def disable_on_not_found!(response)
          return unless response.not_found?

          logger.debug('Agent does not support telemetry; disabling future telemetry events.')
          disable!
        end

        # Deduplicate logs by counting the number of repeated occurrences of the same log
        # entry and replacing them with a single entry with the calculated `count` value.
        # Non-log events are unchanged.
        def deduplicate_logs(events)
          return events if events.empty?

          all_logs = []
          other_events = events.reject do |event|
            if event.is_a?(Event::Log)
              all_logs << event
              true
            else
              false
            end
          end

          return events if all_logs.empty?

          uniq_logs = all_logs.group_by(&:itself).map do |_, logs|
            log = logs.first
            if logs.size > 1
              # New log event with a count of repeated occurrences
              Event::Log.new(message: log.message, level: log.level, stack_trace: log.stack_trace, count: logs.size)
            else
              log
            end
          end

          other_events + uniq_logs
        end
      end
    end
  end
end
