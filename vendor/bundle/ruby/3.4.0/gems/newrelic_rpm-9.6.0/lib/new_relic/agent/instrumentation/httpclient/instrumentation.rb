# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

module NewRelic::Agent::Instrumentation
  module HTTPClient
    module Instrumentation
      INSTRUMENTATION_NAME = 'HTTPClient'

      def with_tracing(request, connection)
        NewRelic::Agent.record_instrumentation_invocation(INSTRUMENTATION_NAME)

        wrapped_request = NewRelic::Agent::HTTPClients::HTTPClientRequest.new(request)
        segment = NewRelic::Agent::Tracer.start_external_request_segment(
          library: wrapped_request.type,
          uri: wrapped_request.uri,
          procedure: wrapped_request.method
        )

        begin
          response = nil
          segment.add_request_headers(wrapped_request)

          NewRelic::Agent::Tracer.capture_segment_error(segment) do
            yield
          end

          response = connection.pop
          connection.push(response)

          wrapped_response = ::NewRelic::Agent::HTTPClients::HTTPClientResponse.new(response)
          segment.process_response_headers(wrapped_response)

          response
        ensure
          ::NewRelic::Agent::Transaction::Segment.finish(segment)
        end
      end
    end
  end
end
