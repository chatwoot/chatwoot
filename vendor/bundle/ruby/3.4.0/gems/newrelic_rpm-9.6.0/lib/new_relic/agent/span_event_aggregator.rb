# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

require 'newrelic_rpm' unless defined?(NewRelic)
require 'new_relic/agent' unless defined?(NewRelic::Agent)
require 'new_relic/agent/event_aggregator'
require 'new_relic/agent/priority_sampled_buffer'

module NewRelic
  module Agent
    class SpanEventAggregator < EventAggregator
      named :SpanEventAggregator
      capacity_key :'span_events.max_samples_stored'

      enabled_keys :'span_events.enabled',
        :'distributed_tracing.enabled'

      def record(priority: nil, event: nil, &blk)
        unless event || priority && blk
          raise ArgumentError, 'Expected priority and block, or event'
        end

        return unless enabled?

        @lock.synchronize do
          @buffer.append(priority: priority, event: event, &blk)
          notify_if_full
        end
      end

      SUPPORTABILITY_TOTAL_SEEN = 'Supportability/SpanEvent/TotalEventsSeen'.freeze
      SUPPORTABILITY_TOTAL_SENT = 'Supportability/SpanEvent/TotalEventsSent'.freeze
      SUPPORTABILITY_DISCARDED = 'Supportability/SpanEvent/Discarded'.freeze

      def after_harvest(metadata)
        seen = metadata[:seen]
        sent = metadata[:captured]
        discarded = seen - sent

        ::NewRelic::Agent.record_metric(SUPPORTABILITY_TOTAL_SEEN, count: seen)
        ::NewRelic::Agent.record_metric(SUPPORTABILITY_TOTAL_SENT, count: sent)
        ::NewRelic::Agent.record_metric(SUPPORTABILITY_DISCARDED, count: discarded)

        super
      end
    end
  end
end
