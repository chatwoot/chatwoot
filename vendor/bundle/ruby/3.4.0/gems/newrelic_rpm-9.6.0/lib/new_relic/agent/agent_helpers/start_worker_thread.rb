# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

module NewRelic
  module Agent
    module AgentHelpers
      module StartWorkerThread
        LOG_ONCE_KEYS_RESET_PERIOD = 60.0

        TRANSACTION_EVENT_DATA = 'transaction_event_data'.freeze
        CUSTOM_EVENT_DATA = 'custom_event_data'.freeze
        ERROR_EVENT_DATA = 'error_event_data'.freeze
        SPAN_EVENT_DATA = 'span_event_data'.freeze
        LOG_EVENT_DATA = 'log_event_data'.freeze

        # Try to launch the worker thread and connect to the server.
        #
        # See #connect for a description of connection_options.
        def start_worker_thread(connection_options = {})
          if disable = NewRelic::Agent.config[:disable_harvest_thread]
            NewRelic::Agent.logger.info('Not starting Ruby Agent worker thread because :disable_harvest_thread is ' \
              "#{disable}")
            return
          end

          ::NewRelic::Agent.logger.debug('Creating Ruby Agent worker thread.')
          @worker_thread = Threading::AgentThread.create('Worker Loop') do
            deferred_work!(connection_options)
          end
        end

        def create_event_loop
          EventLoop.new
        end

        # If the @worker_thread encounters an error during the attempt to connect to the collector
        # then the connect attempts enter an exponential backoff retry loop.  To avoid potential
        # race conditions with shutting down while also attempting to reconnect, we join the
        # @worker_thread with a timeout threshold.  This allows potentially connecting and flushing
        # pending data to the server, but without waiting indefinitely for a reconnect to succeed.
        # The use-case where this typically arises is in cronjob scheduled rake tasks where there's
        # also some network stability/latency issues happening.
        def stop_event_loop
          @event_loop&.stop
          # Wait the end of the event loop thread.
          if @worker_thread
            unless @worker_thread.join(3)
              ::NewRelic::Agent.logger.debug('Event loop thread did not stop within 3 seconds')
            end
          end
        end

        # Certain event types may sometimes need to be on the same interval as metrics,
        # so we will check config assigned in EventHarvestConfig to determine the interval
        # on which to report them
        def interval_for(event_type)
          interval = Agent.config[:"event_report_period.#{event_type}"]
          :"#{interval}_second_harvest"
        end

        def create_and_run_event_loop
          @event_loop = create_event_loop
          data_harvest = :"#{Agent.config[:data_report_period]}_second_harvest"
          @event_loop.on(data_harvest) do
            transmit_data
          end
          establish_interval_transmissions
          establish_fire_everies(data_harvest)

          @event_loop.run
        end

        # Handles the case where the server tells us to restart -
        # this clears the data, clears connection attempts, and
        # waits a while to reconnect.
        def handle_force_restart(error)
          ::NewRelic::Agent.logger.debug(error.message)
          drop_buffered_data
          @service&.force_restart
          @connect_state = :pending
          sleep(30)
        end

        # when a disconnect is requested, stop the current thread, which
        # is the worker thread that gathers data and talks to the
        # server.
        def handle_force_disconnect(error)
          ::NewRelic::Agent.logger.warn('Agent received a ForceDisconnectException from the server, disconnecting. ' \
            "(#{error.message})")
          disconnect
        end

        # Handles an unknown error in the worker thread by logging
        # it and disconnecting the agent, since we are now in an
        # unknown state.
        def handle_other_error(error)
          ::NewRelic::Agent.logger.error('Unhandled error in worker thread, disconnecting.')
          # These errors are fatal (that is, they will prevent the agent from
          # reporting entirely), so we really want backtraces when they happen
          ::NewRelic::Agent.logger.log_exception(:error, error)
          disconnect
        end

        # a wrapper method to handle all the errors that can happen
        # in the connection and worker thread system. This
        # guarantees a no-throw from the background thread.
        def catch_errors
          yield
        rescue NewRelic::Agent::ForceRestartException => e
          handle_force_restart(e)
          retry
        rescue NewRelic::Agent::ForceDisconnectException => e
          handle_force_disconnect(e)
        rescue => e
          handle_other_error(e)
        end

        # This is the method that is run in a new thread in order to
        # background the harvesting and sending of data during the
        # normal operation of the agent.
        #
        # Takes connection options that determine how we should
        # connect to the server, and loops endlessly - typically we
        # never return from this method unless we're shutting down
        # the agent
        def deferred_work!(connection_options)
          catch_errors do
            NewRelic::Agent.disable_all_tracing do
              connect(connection_options)
              if connected?
                create_and_run_event_loop
                # never reaches here unless there is a problem or
                # the agent is exiting
              else
                ::NewRelic::Agent.logger.debug('No connection.  Worker thread ending.')
              end
            end
          end
        end

        private

        def establish_interval_transmissions
          @event_loop.on(interval_for(TRANSACTION_EVENT_DATA)) do
            transmit_analytic_event_data
          end
          @event_loop.on(interval_for(CUSTOM_EVENT_DATA)) do
            transmit_custom_event_data
          end
          @event_loop.on(interval_for(ERROR_EVENT_DATA)) do
            transmit_error_event_data
          end
          @event_loop.on(interval_for(SPAN_EVENT_DATA)) do
            transmit_span_event_data
          end
          @event_loop.on(interval_for(LOG_EVENT_DATA)) do
            transmit_log_event_data
          end
        end

        def establish_fire_everies(data_harvest)
          @event_loop.on(:reset_log_once_keys) do
            ::NewRelic::Agent.logger.clear_already_logged
          end

          event_harvest = :"#{Agent.config[:event_report_period]}_second_harvest"
          @event_loop.fire_every(Agent.config[:data_report_period], data_harvest)
          @event_loop.fire_every(Agent.config[:event_report_period], event_harvest)
          @event_loop.fire_every(LOG_ONCE_KEYS_RESET_PERIOD, :reset_log_once_keys)
        end
      end
    end
  end
end
