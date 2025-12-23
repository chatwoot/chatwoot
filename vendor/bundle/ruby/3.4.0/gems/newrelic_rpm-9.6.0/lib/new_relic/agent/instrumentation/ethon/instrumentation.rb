# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

require 'new_relic/agent/http_clients/ethon_wrappers'

module NewRelic::Agent::Instrumentation
  module Ethon
    module NRShared
      INSTRUMENTATION_NAME = 'Ethon'
      NOTICEABLE_ERROR_CLASS = 'Ethon::Errors::EthonError'

      def prep_easy(easy, parent = nil)
        wrapped_request = NewRelic::Agent::HTTPClients::EthonHTTPRequest.new(easy)
        segment = NewRelic::Agent::Tracer.start_external_request_segment(
          library: wrapped_request.type,
          uri: wrapped_request.uri,
          procedure: wrapped_request.method,
          parent: parent
        )
        segment.add_request_headers(wrapped_request)

        callback = proc do
          wrapped_response = NewRelic::Agent::HTTPClients::EthonHTTPResponse.new(easy)
          segment.process_response_headers(wrapped_response)

          if easy.return_code != :ok
            e = NewRelic::Agent::NoticeableError.new(NOTICEABLE_ERROR_CLASS,
              "return_code: >>#{easy.return_code}<<, response_code: >>#{easy.response_code}<<")
            segment.notice_error(e)
          end

          ::NewRelic::Agent::Transaction::Segment.finish(segment)
        end

        easy.on_complete { callback.call }

        segment
      end

      def wrap_with_tracing(segment, &block)
        NewRelic::Agent.record_instrumentation_invocation(INSTRUMENTATION_NAME)

        NewRelic::Agent::Tracer.capture_segment_error(segment) do
          yield
        end
      ensure
        NewRelic::Agent::Transaction::Segment.finish(segment)
      end
    end

    module Easy
      include NRShared

      ACTION_INSTANCE_VAR = :@nr_action
      HEADERS_INSTANCE_VAR = :@nr_headers

      # `Ethon::Easy` doesn't expose the "action name" ('GET', 'POST', etc.)
      # and Ethon's fabrication of HTTP classes uses
      # `Ethon::Easy::Http::Custom` for non-standard actions. To be able to
      # know the action name at `#perform` time, we set a new instance variable
      # on the `Ethon::Easy` instance with the base name of the fabricated
      # class, respecting the 'Custom' name where appropriate.
      def fabricate_with_tracing(_url, action_name, _options)
        fabbed = yield
        instance_variable_set(ACTION_INSTANCE_VAR, NewRelic::Agent.base_name(fabbed.class.name).upcase)
        fabbed
      end

      # `Ethon::Easy` uses `Ethon::Easy::Header` to set request headers on
      # libcurl with `#headers=`. After they are set, they aren't easy to get
      # at again except via FFI so set a new instance variable on the
      # `Ethon::Easy` instance to store them in Ruby hash format.
      def headers_equals_with_tracing(headers)
        instance_variable_set(HEADERS_INSTANCE_VAR, headers)
        yield
      end

      def perform_with_tracing(*args)
        return unless NewRelic::Agent::Tracer.state.is_execution_traced?

        segment = prep_easy(self)
        wrap_with_tracing(segment) { yield }
      end
    end

    module Multi
      include NRShared

      MULTI_SEGMENT_NAME = 'External/Multiple/Ethon::Multi/perform'

      def perform_with_tracing(*args)
        return unless NewRelic::Agent::Tracer.state.is_execution_traced?

        segment = NewRelic::Agent::Tracer.start_segment(name: MULTI_SEGMENT_NAME)

        wrap_with_tracing(segment) do
          easy_handles.each { |easy| prep_easy(easy, segment) }

          yield
        end
      end
    end
  end
end
