# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

require 'new_relic/agent/http_clients/async_http_wrappers'

module NewRelic::Agent::Instrumentation
  module AsyncHttp
    def call_with_new_relic(method, url, headers = nil, body = nil)
      headers ||= {} # if it is nil, we need to make it a hash so we can insert headers
      wrapped_request = NewRelic::Agent::HTTPClients::AsyncHTTPRequest.new(self, method, url, headers)

      segment = NewRelic::Agent::Tracer.start_external_request_segment(
        library: wrapped_request.type,
        uri: wrapped_request.uri,
        procedure: wrapped_request.method
      )

      begin
        response = nil
        segment.add_request_headers(wrapped_request)

        NewRelic::Agent.disable_all_tracing do
          response = NewRelic::Agent::Tracer.capture_segment_error(segment) do
            yield(headers)
          end
        end

        wrapped_response = NewRelic::Agent::HTTPClients::AsyncHTTPResponse.new(response)
        segment.process_response_headers(wrapped_response)
        response
      ensure
        segment&.finish
      end
    end
  end
end
