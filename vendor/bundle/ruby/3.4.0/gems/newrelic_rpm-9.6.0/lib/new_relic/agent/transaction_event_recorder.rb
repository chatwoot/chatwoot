# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

require 'new_relic/agent/transaction_event_aggregator'
require 'new_relic/agent/synthetics_event_aggregator'
require 'new_relic/agent/transaction_event_primitive'

module NewRelic
  module Agent
    # This is responsible for recording transaction events and managing
    # the relationship between events generated from synthetics requests
    # vs normal requests.
    class TransactionEventRecorder
      attr_reader :transaction_event_aggregator
      attr_reader :synthetics_event_aggregator

      def initialize(events)
        @transaction_event_aggregator = NewRelic::Agent::TransactionEventAggregator.new(events)
        @synthetics_event_aggregator = NewRelic::Agent::SyntheticsEventAggregator.new(events)
      end

      def record(payload)
        return unless NewRelic::Agent.config[:'transaction_events.enabled']

        if synthetics_event?(payload)
          event = create_event(payload)
          result = synthetics_event_aggregator.record(event)
          transaction_event_aggregator.record(event: event) if result.nil?
        else
          transaction_event_aggregator.record(priority: payload[:priority]) { create_event(payload) }
        end
      end

      def create_event(payload)
        TransactionEventPrimitive.create(payload)
      end

      def synthetics_event?(payload)
        payload.key?(:synthetics_resource_id)
      end

      def drop_buffered_data
        transaction_event_aggregator.reset!
        synthetics_event_aggregator.reset!
      end
    end
  end
end
