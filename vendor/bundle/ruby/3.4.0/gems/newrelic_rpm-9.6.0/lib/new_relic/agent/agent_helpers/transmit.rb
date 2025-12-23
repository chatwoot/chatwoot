# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

module NewRelic
  module Agent
    module AgentHelpers
      module Transmit
        TRANSACTION_EVENT = 'TransactionEvent'.freeze
        def transmit_analytic_event_data
          transmit_single_data_type(:harvest_and_send_analytic_event_data, TRANSACTION_EVENT)
        end

        CUSTOM_EVENT = 'CustomEvent'.freeze
        def transmit_custom_event_data
          transmit_single_data_type(:harvest_and_send_custom_event_data, CUSTOM_EVENT)
        end

        ERROR_EVENT = 'ErrorEvent'.freeze
        def transmit_error_event_data
          transmit_single_data_type(:harvest_and_send_error_event_data, ERROR_EVENT)
        end

        SPAN_EVENT = 'SpanEvent'.freeze
        def transmit_span_event_data
          transmit_single_data_type(:harvest_and_send_span_event_data, SPAN_EVENT)
        end

        LOG_EVENT = 'LogEvent'.freeze
        def transmit_log_event_data
          transmit_single_data_type(:harvest_and_send_log_event_data, LOG_EVENT)
        end

        def transmit_single_data_type(harvest_method, supportability_name)
          now = Process.clock_gettime(Process::CLOCK_MONOTONIC)

          msg = "Sending #{supportability_name} data to New Relic Service"
          ::NewRelic::Agent.logger.debug(msg)

          @service.session do # use http keep-alive
            self.send(harvest_method)
          end
        ensure
          duration = Process.clock_gettime(Process::CLOCK_MONOTONIC) - now
          NewRelic::Agent.record_metric("Supportability/#{supportability_name}Harvest", duration)
        end

        def transmit_data
          now = Process.clock_gettime(Process::CLOCK_MONOTONIC)
          ::NewRelic::Agent.logger.debug('Sending data to New Relic Service')

          @events.notify(:before_harvest)
          @service.session do # use http keep-alive
            harvest_and_send_data_types

            check_for_and_handle_agent_commands
            harvest_and_send_for_agent_commands
          end
        ensure
          NewRelic::Agent::Database.close_connections
          duration = Process.clock_gettime(Process::CLOCK_MONOTONIC) - now
          NewRelic::Agent.record_metric('Supportability/Harvest', duration)
        end

        def transmit_data_types
          transmit_data
          transmit_analytic_event_data
          transmit_custom_event_data
          transmit_error_event_data
          transmit_span_event_data
          transmit_log_event_data
        end
      end
    end
  end
end
