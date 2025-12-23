# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

module NewRelic
  module Agent
    module AgentHelpers
      module Shutdown
        # Attempt a graceful shutdown of the agent, flushing any remaining
        # data.
        def shutdown
          return unless started?

          ::NewRelic::Agent.logger.info('Starting Agent shutdown')

          stop_event_loop
          trap_signals_for_litespeed
          untraced_graceful_disconnect
          revert_to_default_configuration

          @started = nil
          Control.reset
        end

        def untraced_graceful_disconnect
          begin
            NewRelic::Agent.disable_all_tracing do
              graceful_disconnect
            end
          rescue => e
            ::NewRelic::Agent.logger.error(e)
          end
        end

        # This method contacts the server to send remaining data and
        # let the server know that the agent is shutting down - this
        # allows us to do things like accurately set the end of the
        # lifetime of the process
        #
        # If this process comes from a parent process, it will not
        # disconnect, so that the parent process can continue to send data
        def graceful_disconnect
          if connected?
            begin
              @service.request_timeout = 10

              @events.notify(:before_shutdown)
              transmit_data_types
              shutdown_service

              ::NewRelic::Agent.logger.debug('Graceful disconnect complete')
            rescue Timeout::Error, StandardError => e
              ::NewRelic::Agent.logger.debug("Error when disconnecting #{e.class.name}: #{e.message}")
            end
          else
            ::NewRelic::Agent.logger.debug('Bypassing graceful disconnect - agent not connected')
          end
        end

        def shutdown_service
          if @connected_pid == $$ && !@service.kind_of?(NewRelic::Agent::NewRelicService)
            ::NewRelic::Agent.logger.debug('Sending New Relic service agent run shutdown message')
            @service.shutdown
          else
            ::NewRelic::Agent.logger.debug("This agent connected from parent process #{@connected_pid}--not sending " \
              'shutdown')
          end
        end
      end
    end
  end
end
