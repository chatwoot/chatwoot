# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

require 'new_relic/agent/distributed_tracing/distributed_trace_payload'
require 'new_relic/agent/distributed_tracing/distributed_trace_attributes'
require 'new_relic/agent/distributed_tracing/distributed_trace_metrics'

module NewRelic
  module Agent
    class Transaction
      module DistributedTracing
        attr_accessor :distributed_trace_payload
        attr_writer :distributed_trace_payload_created

        SUPPORTABILITY_DISTRIBUTED_TRACE = 'Supportability/DistributedTrace'
        CREATE_PREFIX = "#{SUPPORTABILITY_DISTRIBUTED_TRACE}/CreatePayload"
        ACCEPT_PREFIX = "#{SUPPORTABILITY_DISTRIBUTED_TRACE}/AcceptPayload"
        IGNORE_PREFIX = "#{ACCEPT_PREFIX}/Ignored"

        CREATE_SUCCESS_METRIC = "#{CREATE_PREFIX}/Success"
        CREATE_EXCEPTION_METRIC = "#{CREATE_PREFIX}/Exception"
        ACCEPT_SUCCESS_METRIC = "#{ACCEPT_PREFIX}/Success"
        ACCEPT_EXCEPTION_METRIC = "#{ACCEPT_PREFIX}/Exception"
        ACCEPT_PARSE_EXCEPTION_METRIC = "#{ACCEPT_PREFIX}/ParseException"

        IGNORE_ACCEPT_AFTER_CREATE_METRIC = "#{IGNORE_PREFIX}/CreateBeforeAccept"
        IGNORE_MULTIPLE_ACCEPT_METRIC = "#{IGNORE_PREFIX}/Multiple"
        IGNORE_ACCEPT_NULL_METRIC = "#{IGNORE_PREFIX}/Null"
        IGNORE_ACCEPT_MAJOR_VERSION_METRIC = "#{IGNORE_PREFIX}/MajorVersion"
        IGNORE_ACCEPT_UNTRUSTED_ACCOUNT_METRIC = "#{IGNORE_PREFIX}/UntrustedAccount"

        LBRACE = '{'
        NULL_PAYLOAD = 'null'

        NEWRELIC_TRACE_KEY = 'HTTP_NEWRELIC'

        def accept_distributed_tracing_incoming_request(request)
          return unless Agent.config[:'distributed_tracing.enabled']
          return unless payload = request[NEWRELIC_TRACE_KEY]

          accept_distributed_trace_payload(payload)
        end

        def distributed_trace_payload_created?
          @distributed_trace_payload_created ||= false
        end

        def create_distributed_trace_payload
          return unless Agent.config[:'distributed_tracing.enabled']

          @distributed_trace_payload_created = true
          payload = DistributedTracePayload.for_transaction(transaction)
          NewRelic::Agent.increment_metric(CREATE_SUCCESS_METRIC)
          payload
        rescue => e
          NewRelic::Agent.increment_metric(CREATE_EXCEPTION_METRIC)
          NewRelic::Agent.logger.warn('Failed to create distributed trace payload', e)
          nil
        end

        def accept_distributed_trace_payload(payload)
          return unless Agent.config[:'distributed_tracing.enabled']

          return false if check_payload_ignored(payload)
          return false unless check_payload_present(payload)
          return false unless payload = decode_payload(payload)
          return false unless check_required_fields_present(payload)
          return false unless check_valid_version(payload)
          return false unless check_trusted_account(payload)

          assign_payload_and_sampling_params(payload)

          NewRelic::Agent.increment_metric(ACCEPT_SUCCESS_METRIC)
          true
        rescue => e
          NewRelic::Agent.increment_metric(ACCEPT_EXCEPTION_METRIC)
          NewRelic::Agent.logger.warn('Failed to accept distributed trace payload', e)
          false
        end

        private

        def check_payload_ignored(payload)
          if distributed_trace_payload
            NewRelic::Agent.increment_metric(IGNORE_MULTIPLE_ACCEPT_METRIC)
            return true
          elsif distributed_trace_payload_created?
            NewRelic::Agent.increment_metric(IGNORE_ACCEPT_AFTER_CREATE_METRIC)
            return true
          end
          false
        end

        def check_payload_present(payload)
          # We might be passed a Ruby `nil` object _or_ the JSON "null"
          if payload.nil? || payload == NULL_PAYLOAD
            NewRelic::Agent.increment_metric(IGNORE_ACCEPT_NULL_METRIC)
            return nil
          end

          payload
        end

        def decode_payload(payload)
          decoded = if payload.start_with?(LBRACE)
            DistributedTracePayload.from_json(payload)
          else
            DistributedTracePayload.from_http_safe(payload)
          end

          return nil unless check_payload_present(decoded)

          decoded
        rescue => e
          NewRelic::Agent.increment_metric(ACCEPT_PARSE_EXCEPTION_METRIC)
          NewRelic::Agent.logger.warn('Error parsing distributed trace payload', e)
          nil
        end

        def check_required_fields_present(payload)
          if !payload.version.nil? &&
              !payload.parent_account_id.nil? &&
              !payload.parent_app_id.nil? &&
              !payload.parent_type.nil? &&
              (!payload.transaction_id.nil? || !payload.id.nil?) &&
              !payload.trace_id.nil? &&
              !payload.timestamp.nil?

            true
          else
            NewRelic::Agent.increment_metric(ACCEPT_PARSE_EXCEPTION_METRIC)
            false
          end
        end

        def check_valid_version(payload)
          if DistributedTracePayload.major_version_matches?(payload)
            true
          else
            NewRelic::Agent.increment_metric(IGNORE_ACCEPT_MAJOR_VERSION_METRIC)
            false
          end
        end

        def check_trusted_account(payload)
          compare_key = payload.trusted_account_key || payload.parent_account_id
          unless compare_key == NewRelic::Agent.config[:trusted_account_key]
            NewRelic::Agent.increment_metric(IGNORE_ACCEPT_UNTRUSTED_ACCOUNT_METRIC)
            return false
          end
          true
        end

        def assign_payload_and_sampling_params(payload)
          @distributed_trace_payload = payload
          return if transaction.distributed_tracer.trace_context_header_data

          transaction.trace_id = payload.trace_id
          transaction.distributed_tracer.parent_transaction_id = payload.transaction_id
          transaction.parent_span_id = payload.id

          unless payload.sampled.nil?
            transaction.sampled = payload.sampled
            transaction.priority = payload.priority if payload.priority
          end
        end
      end
    end
  end
end
