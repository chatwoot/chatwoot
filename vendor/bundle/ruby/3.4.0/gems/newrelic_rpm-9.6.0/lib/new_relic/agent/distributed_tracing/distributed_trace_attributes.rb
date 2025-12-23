# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

module NewRelic
  module Agent
    module DistributedTraceAttributes
      extend self

      # Intrinsic Keys
      INTRINSIC_KEYS = [
        PARENT_TYPE_KEY = 'parent.type',
        PARENT_APP_KEY = 'parent.app',
        PARENT_ACCOUNT_ID_KEY = 'parent.account',
        PARENT_TRANSPORT_TYPE_KEY = 'parent.transportType',
        PARENT_TRANSPORT_DURATION_KEY = 'parent.transportDuration',
        GUID_KEY = 'guid',
        TRACE_ID_KEY = 'traceId',
        PARENT_TRANSACTION_ID_KEY = 'parentId',
        PARENT_SPAN_ID_KEY = 'parentSpanId',
        SAMPLED_KEY = 'sampled'
      ].freeze

      # This method extracts intrinsics from the transaction_payload and
      # inserts them into the specified destination.
      def copy_to_hash(transaction_payload, destination)
        return unless enabled?

        INTRINSIC_KEYS.each do |key|
          value = transaction_payload[key]
          destination[key] = value unless value.nil?
        end
      end

      # This method extracts intrinsics from the transaction_payload and
      # inserts them as intrinsics in the specified transaction_attributes
      def copy_to_attributes(transaction_payload, destination)
        return unless enabled?

        INTRINSIC_KEYS.each do |key|
          next unless transaction_payload.key?(key)

          destination.add_intrinsic_attribute(key, transaction_payload[key])
        end
      end

      # This method takes all distributed tracing intrinsics from the transaction
      # and the trace_payload, and populates them into the destination
      def copy_from_transaction(transaction, trace_payload, destination)
        destination[GUID_KEY] = transaction.guid
        destination[SAMPLED_KEY] = transaction.sampled?
        destination[TRACE_ID_KEY] = transaction.trace_id

        if transaction.parent_span_id
          destination[PARENT_SPAN_ID_KEY] = transaction.parent_span_id
        end

        copy_parent_attributes(transaction, trace_payload, destination)
      end

      def copy_parent_attributes(transaction, trace_payload, destination)
        transport_type = transaction.distributed_tracer.caller_transport_type
        destination[PARENT_TRANSPORT_TYPE_KEY] = DistributedTraceTransportType.from(transport_type)

        if trace_payload
          destination[PARENT_TYPE_KEY] = trace_payload.parent_type
          destination[PARENT_APP_KEY] = trace_payload.parent_app_id
          destination[PARENT_ACCOUNT_ID_KEY] = trace_payload.parent_account_id
          destination[PARENT_TRANSPORT_DURATION_KEY] = transaction.calculate_transport_duration(trace_payload)

          if parent_transaction_id = transaction.distributed_tracer.parent_transaction_id
            destination[PARENT_TRANSACTION_ID_KEY] = parent_transaction_id
          end
        end
      end

      private

      def enabled?
        return Agent.config[:'distributed_tracing.enabled']
      end
    end
  end
end
