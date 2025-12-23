# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

require 'new_relic/agent/http_clients/httpx_wrappers'

module NewRelic::Agent::Instrumentation::HTTPX
  INSTRUMENTATION_NAME = 'HTTPX'
  NOTICEABLE_ERROR_CLASS = 'HTTPX::Error'

  def send_requests_with_tracing(*requests)
    NewRelic::Agent.record_instrumentation_invocation(INSTRUMENTATION_NAME)
    requests.each { |r| nr_start_segment(r) }
    yield
  end

  def nr_start_segment(request)
    return unless NewRelic::Agent::Tracer.state.is_execution_traced?

    wrapped_request = NewRelic::Agent::HTTPClients::HTTPXHTTPRequest.new(request)
    segment = NewRelic::Agent::Tracer.start_external_request_segment(
      library: wrapped_request.type,
      uri: wrapped_request.uri,
      procedure: wrapped_request.method
    )
    segment.add_request_headers(wrapped_request)

    request.on(:response) { nr_finish_segment.call(request, segment) }
  end

  def nr_finish_segment
    proc do |request, segment|
      response = @responses[request]

      unless response
        NewRelic::Agent.logger.debug('Processed an on-response callback for HTTPX but could not find the response!')
        next
      end

      wrapped_response = NewRelic::Agent::HTTPClients::HTTPXHTTPResponse.new(response)
      segment.process_response_headers(wrapped_response)

      if response.is_a?(::HTTPX::ErrorResponse)
        e = NewRelic::Agent::NoticeableError.new(NOTICEABLE_ERROR_CLASS, "Couldn't connect: #{response}")
        segment.notice_error(e)
      end

      ::NewRelic::Agent::Transaction::Segment.finish(segment)
    end
  end
end
