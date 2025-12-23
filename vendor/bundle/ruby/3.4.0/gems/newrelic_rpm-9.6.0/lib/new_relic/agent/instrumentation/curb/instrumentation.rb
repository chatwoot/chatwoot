# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

module NewRelic
  module Agent
    module Instrumentation
      module Curb
        module Easy
          attr_accessor :_nr_instrumented,
            :_nr_http_verb,
            :_nr_header_str,
            :_nr_original_on_header,
            :_nr_original_on_complete,
            :_nr_original_on_failure,
            :_nr_serial

          # We have to hook these three methods separately, as they don't use
          # Curl::Easy#http
          def http_head_with_tracing
            self._nr_http_verb = :HEAD
            yield
          end

          def http_post_with_tracing
            self._nr_http_verb = :POST
            yield
          end

          def http_put_with_tracing
            self._nr_http_verb = :PUT
            yield
          end

          # Hook the #http method to set the verb.
          def http_with_tracing(verb)
            self._nr_http_verb = verb.to_s.upcase
            yield
          end

          # Hook the #perform method to mark the request as non-parallel.
          def perform_with_tracing
            self._nr_http_verb ||= :GET
            self._nr_serial = true
            yield
          end

          # Record the HTTP verb for future #perform calls
          def method_with_tracing(verb)
            self._nr_http_verb = verb.upcase
            yield
          end

          # We override this method in order to ensure access to header_str even
          # though we use an on_header callback
          def header_str_with_tracing
            if self._nr_serial
              self._nr_header_str
            else
              # Since we didn't install a header callback for a non-serial request,
              # just fall back to the original implementation.
              yield
            end
          end
        end
        ####################################################

        module Multi
          include NewRelic::Agent::MethodTracer

          INSTRUMENTATION_NAME = 'Curb'

          # Add CAT with callbacks if the request is serial
          def add_with_tracing(curl)
            if curl.respond_to?(:_nr_serial) && curl._nr_serial
              hook_pending_request(curl) if NewRelic::Agent::Tracer.tracing_enabled?
            end

            return yield
          end

          # Trace as an External/Multiple call if the first request isn't serial.
          def perform_with_tracing
            return yield if first_request_is_serial?

            NewRelic::Agent.record_instrumentation_invocation(INSTRUMENTATION_NAME)

            trace_execution_scoped('External/Multiple/Curb::Multi/perform') do
              yield
            end
          end

          # Instrument the specified +request+ (a Curl::Easy object)
          # and set up cross-application tracing if it's enabled.
          def hook_pending_request(request)
            wrapped_request, wrapped_response = wrap_request(request)

            segment = NewRelic::Agent::Tracer.start_external_request_segment(
              library: wrapped_request.type,
              uri: wrapped_request.uri,
              procedure: wrapped_request.method
            )

            segment.add_request_headers(wrapped_request)

            # install all callbacks
            unless request._nr_instrumented
              install_header_callback(request, wrapped_response)
              install_completion_callback(request, wrapped_response, segment)
              install_failure_callback(request, wrapped_response, segment)
              request._nr_instrumented = true
            end
          rescue => err
            NewRelic::Agent.logger.error('Untrapped exception', err)
          end

          # Create request and response adapter objects for the specified +request+
          # NOTE: Although strange to wrap request and response at once, it works
          # because curb's callback mechanism updates the instantiated wrappers
          # during the life-cycle of external request
          def wrap_request(request)
            return NewRelic::Agent::HTTPClients::CurbRequest.new(request),
                    NewRelic::Agent::HTTPClients::CurbResponse.new(request)
          end

          # Install a callback that will record the response headers
          # to enable CAT linking
          def install_header_callback(request, wrapped_response)
            original_callback = request.on_header
            request._nr_original_on_header = original_callback
            request._nr_header_str = nil
            request.on_header do |header_data|
              if original_callback
                original_callback.call(header_data)
              else
                wrapped_response.append_header_data(header_data)
                header_data.length
              end
            end
          end

          # Install a callback that will finish the trace.
          def install_completion_callback(request, wrapped_response, segment)
            original_callback = request.on_complete
            request._nr_original_on_complete = original_callback
            request.on_complete do |finished_request|
              begin
                segment&.process_response_headers(wrapped_response)
              ensure
                ::NewRelic::Agent::Transaction::Segment.finish(segment)
                # Make sure the existing completion callback is run, and restore the
                # on_complete callback to how it was before.
                original_callback&.call(finished_request)
                remove_instrumentation_callbacks(request)
              end
            end
          end

          # Install a callback that will fire on failures
          # NOTE:  on_failure is not always called, so we're not always
          # unhooking the callback.  No harm/no foul in production, but
          # definitely something to beware of if debugging callback issues
          # @__newrelic_original_callback exists to prevent infinitely chaining
          # our on_failure callback hook.
          def install_failure_callback(request, _wrapped_response, segment)
            original_callback = request.on_failure

            nr_original_callback = original_callback.instance_variable_get(:@__newrelic_original_callback)
            original_callback = nr_original_callback || original_callback

            request._nr_original_on_failure = original_callback

            newrelic_callback = proc do |failed_request, error|
              begin
                if segment
                  noticeable_error = NewRelic::Agent::NoticeableError.new(error[0].name, error[-1])
                  segment.notice_error(noticeable_error)
                end
              ensure
                original_callback&.call(failed_request, error)
                remove_failure_callback(failed_request)
              end
            end
            newrelic_callback.instance_variable_set(:@__newrelic_original_callback, original_callback)

            request.on_failure(&newrelic_callback)
          end

          # on_failure callbacks cannot be removed in the on_complete
          # callback where this method is invoked because on_complete
          # fires before the on_failure!
          def remove_instrumentation_callbacks(request)
            request.on_complete(&request._nr_original_on_complete)
            request.on_header(&request._nr_original_on_header)
            request._nr_instrumented = false
          end

          # We execute customer's on_failure callback (if any) and
          # uninstall our hook here since the on_complete callback
          # fires before the on_failure callback.
          def remove_failure_callback(request)
            request.on_failure(&request._nr_original_on_failure)
          end

          private

          def first_request_is_serial?
            return false unless (first = self.requests.first)

            # Before curb 0.9.8, requests was an array of Curl::Easy
            # instances.  Starting with 0.9.8, it's a Hash where the
            # values are Curl::Easy instances.
            #
            # So, requests.first will either be an_obj or [a_key, an_obj].
            # We need to handle either case.
            #
            first = first[-1] if first.is_a?(Array)

            first.respond_to?(:_nr_serial) && first._nr_serial
          end
        end
      end
    end
  end
end
