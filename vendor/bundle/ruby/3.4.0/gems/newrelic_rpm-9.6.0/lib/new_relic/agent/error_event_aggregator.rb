# -*- ruby -*-
# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

require 'new_relic/agent/event_aggregator'
require 'new_relic/agent/transaction_error_primitive'
require 'new_relic/agent/priority_sampled_buffer'

module NewRelic
  module Agent
    class ErrorEventAggregator < EventAggregator
      include NewRelic::Coerce

      named :ErrorEventAggregator
      capacity_key :'error_collector.max_event_samples_stored'
      enabled_keys :'error_collector.enabled',
        :'error_collector.capture_events'
      buffer_class PrioritySampledBuffer

      def record(noticed_error, transaction_payload = nil, span_id = nil)
        return unless enabled?

        priority = float!((transaction_payload && transaction_payload[:priority]) || rand)

        @lock.synchronize do
          @buffer.append(priority: priority) do
            create_event(noticed_error, transaction_payload, span_id)
          end
          notify_if_full
        end
      end

      private

      def create_event(noticed_error, transaction_payload, span_id)
        TransactionErrorPrimitive.create(noticed_error, transaction_payload, span_id)
      end
    end
  end
end
