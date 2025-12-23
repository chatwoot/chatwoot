# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

module NewRelic::Agent::Instrumentation
  module HTTPrb
    INSTRUMENTATION_NAME = NewRelic::Agent.base_name(name)

    def with_tracing(request)
      NewRelic::Agent.record_instrumentation_invocation(INSTRUMENTATION_NAME)

      wrapped_request = ::NewRelic::Agent::HTTPClients::HTTPRequest.new(request)

      begin
        segment = NewRelic::Agent::Tracer.start_external_request_segment(
          library: wrapped_request.type,
          uri: wrapped_request.uri,
          procedure: wrapped_request.method
        )

        segment.add_request_headers(wrapped_request)

        response = NewRelic::Agent::Tracer.capture_segment_error(segment) { yield }

        wrapped_response = ::NewRelic::Agent::HTTPClients::HTTPResponse.new(response)
        segment.process_response_headers(wrapped_response)

        response
      ensure
        ::NewRelic::Agent::Transaction::Segment.finish(segment)
      end
    end
  end
end
