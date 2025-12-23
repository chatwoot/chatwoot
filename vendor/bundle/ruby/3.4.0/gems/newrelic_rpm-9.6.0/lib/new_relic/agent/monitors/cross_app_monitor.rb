# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

require 'digest'
require 'json'

require 'new_relic/agent/tracer'
require 'new_relic/agent/threading/agent_thread'

module NewRelic
  module Agent
    module DistributedTracing
      class CrossAppMonitor < InboundRequestMonitor
        NEWRELIC_TXN_HEADER = 'X-NewRelic-Transaction'.freeze
        NEWRELIC_APPDATA_HEADER = 'X-NewRelic-App-Data'.freeze

        NEWRELIC_ID_HEADER_KEY = 'HTTP_X_NEWRELIC_ID'.freeze
        NEWRELIC_TXN_HEADER_KEY = 'HTTP_X_NEWRELIC_TRANSACTION'.freeze
        CONTENT_LENGTH_HEADER_KEY = 'HTTP_CONTENT_LENGTH'.freeze

        def on_finished_configuring(events)
          if CrossAppTracing.cross_app_enabled?
            Deprecator.deprecate('cross_application_tracer')
            ::NewRelic::Agent.logger.warn(
              '[DEPRECATED] Cross application tracing is enabled. Distributed tracing is replacing cross application tracing as the default means of tracing between services. To continue using cross application tracing, enable it with `cross_application_tracer.enabled: true` and `distributed_tracing.enabled: false`'
            )
          end

          register_event_listeners(events)
        end

        def path_hash(txn_name, seed)
          rotated = ((seed << 1) | (seed >> 31)) & 0xffffffff
          app_name = NewRelic::Agent.config[:app_name].first
          identifier = "#{app_name};#{txn_name}"
          sprintf('%08x', rotated ^ hash_transaction_name(identifier))
        end

        private

        # Expected sequence of events:
        #   :before_call will save our cross application request id to the thread
        #   :after_call will write our response headers/metrics and clean up the thread
        def register_event_listeners(events)
          NewRelic::Agent.logger
            .debug('Wiring up Cross Application Tracing to events after finished configuring')

          events.subscribe(:before_call) do |env| # THREAD_LOCAL_ACCESS
            if id = decoded_id(env) and should_process_request?(id)
              state = NewRelic::Agent::Tracer.state

              if (txn = state.current_transaction)
                transaction_info = referring_transaction_info(state, env)

                payload = CrossAppPayload.new(id, txn, transaction_info)
                txn.distributed_tracer.cross_app_payload = payload
              end

              CrossAppTracing.assign_intrinsic_transaction_attributes(state)
            end
          end

          events.subscribe(:after_call) do |env, (_status_code, headers, _body)| # THREAD_LOCAL_ACCESS
            state = NewRelic::Agent::Tracer.state

            insert_response_header(state, env, headers)
          end
        end

        def referring_transaction_info(state, request_headers)
          txn_header = request_headers[NEWRELIC_TXN_HEADER_KEY] or return
          deserialize_header(txn_header, NEWRELIC_TXN_HEADER)
        end

        def insert_response_header(state, request_headers, response_headers)
          txn = state.current_transaction
          unless txn.nil? || txn.distributed_tracer.cross_app_payload.nil?
            txn.freeze_name_and_execute_if_not_ignored do
              content_length = content_length_from_request(request_headers)
              set_response_headers(txn, response_headers, content_length)
            end
          end
        end

        def should_process_request?(id)
          CrossAppTracing.cross_app_enabled? && CrossAppTracing.trusts?(id)
        end

        def set_response_headers(transaction, response_headers, content_length)
          payload = obfuscator.obfuscate(
            ::JSON.dump(
              transaction.distributed_tracer.cross_app_payload.as_json_array(content_length)
            )
          )

          response_headers[NEWRELIC_APPDATA_HEADER] = payload
        end

        def decoded_id(request)
          encoded_id = request[NEWRELIC_ID_HEADER_KEY]
          return NewRelic::EMPTY_STR if encoded_id.nil? || encoded_id.empty?

          obfuscator.deobfuscate(encoded_id)
        end

        def content_length_from_request(request)
          request[CONTENT_LENGTH_HEADER_KEY] || -1
        end

        def hash_transaction_name(identifier)
          Digest::MD5.digest(identifier).unpack('@12N').first & 0xffffffff
        end
      end
    end
  end
end
