# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

module ::Excon
  module Middleware
    class NewRelicCrossAppTracing
      TRACE_DATA_IVAR = :@newrelic_trace_data
      INSTRUMENTATION_NAME = 'Excon'

      def initialize(stack)
        @stack = stack
      end

      def request_call(datum) # THREAD_LOCAL_ACCESS
        begin
          # Only instrument this request if we haven't already done so, because
          # we can get request_call multiple times for requests marked as
          # :idempotent in the options, but there will be only a single
          # accompanying response_call/error_call.
          if datum[:connection] && !datum[:connection].instance_variable_get(TRACE_DATA_IVAR)
            NewRelic::Agent.record_instrumentation_invocation(INSTRUMENTATION_NAME)

            wrapped_request = ::NewRelic::Agent::HTTPClients::ExconHTTPRequest.new(datum)
            segment = NewRelic::Agent::Tracer.start_external_request_segment(
              library: wrapped_request.type,
              uri: wrapped_request.uri,
              procedure: wrapped_request.method
            )

            segment.add_request_headers(wrapped_request)

            datum[:connection].instance_variable_set(TRACE_DATA_IVAR, segment)
          end
        rescue => e
          NewRelic::Agent.logger.debug(e)
        end
        @stack.request_call(datum)
      end

      def response_call(datum)
        finish_trace(datum)
        @stack.response_call(datum)
      end

      def error_call(datum)
        finish_trace(datum)
        @stack.error_call(datum)
      end

      def finish_trace(datum) # THREAD_LOCAL_ACCESS
        # The following line needs else branch coverage
        segment = datum[:connection] && datum[:connection].instance_variable_get(TRACE_DATA_IVAR) # rubocop:disable Style/SafeNavigation
        if segment
          begin
            segment.notice_error(datum[:error]) if datum[:error]
            datum[:connection].instance_variable_set(TRACE_DATA_IVAR, nil)

            if datum[:response]
              wrapped_response = ::NewRelic::Agent::HTTPClients::ExconHTTPResponse.new(datum[:response])
              segment.process_response_headers(wrapped_response)
            end
          ensure
            ::NewRelic::Agent::Transaction::Segment.finish(segment)
          end
        end
      end
    end
  end
end
