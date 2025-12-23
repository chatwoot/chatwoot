# -*- ruby -*-
# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

require 'newrelic_rpm' unless defined?(NewRelic)
require 'new_relic/agent' unless defined?(NewRelic::Agent)
require 'new_relic/agent/event_aggregator'
require 'new_relic/agent/priority_sampled_buffer'

module NewRelic
  module Agent
    class TransactionEventAggregator < EventAggregator
      named :TransactionEventAggregator
      capacity_key :'transaction_events.max_samples_stored'
      enabled_key :'transaction_events.enabled'
      buffer_class PrioritySampledBuffer

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

      private

      def after_harvest(metadata)
        return unless enabled?

        record_sampling_rate(metadata)
      end

      def record_sampling_rate(metadata) # THREAD_LOCAL_ACCESS
        NewRelic::Agent.logger.debug('Sampled %d / %d (%.1f %%) requests this cycle, %d / %d (%.1f %%) since startup' % [
          metadata[:captured],
          metadata[:seen],
          (metadata[:captured].to_f / metadata[:seen] * 100.0),
          metadata[:captured_lifetime],
          metadata[:seen_lifetime],
          (metadata[:captured_lifetime].to_f / metadata[:seen_lifetime] * 100.0)
        ])

        engine = NewRelic::Agent.instance.stats_engine
        engine.tl_record_supportability_metric_count('TransactionEventAggregator/requests', metadata[:seen])
        engine.tl_record_supportability_metric_count('TransactionEventAggregator/samples', metadata[:captured])
      end
    end
  end
end
