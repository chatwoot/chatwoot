# -*- ruby -*-
# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

module NewRelic
  module Agent
    module PayloadMetricMapping
      # this logic was extracted from TransactionEventAggregator for reuse by
      # the ErrorEventAggregator

      SPEC_MAPPINGS = {}

      class << self
        def append_mapped_metrics(txn_metrics, sample)
          if txn_metrics
            SPEC_MAPPINGS.each do |(name, extracted_values)|
              if txn_metrics.has_key?(name)
                stat = txn_metrics[name]
                extracted_values.each do |value_name, key_name|
                  sample[key_name] = stat.send(value_name)
                end
              end
            end
          end
        end

        private

        def map_metric(metric_name, to_add = {})
          to_add.values.each(&:freeze)

          mappings = SPEC_MAPPINGS.fetch(metric_name, {})
          mappings.merge!(to_add)

          SPEC_MAPPINGS[metric_name] = mappings
        end
      end

      # All Transactions
      # Don't need to use the transaction-type specific metrics since this is
      # scoped to just one transaction, so Datastore/all has what we want.
      map_metric('Datastore/all', :total_call_time => 'databaseDuration')
      map_metric('Datastore/all', :call_count => 'databaseCallCount')
      map_metric('GC/Transaction/all', :total_call_time => 'gcCumulative')

      # Web Metrics
      map_metric('WebFrontend/QueueTime', :total_call_time => 'queueDuration')
      map_metric('External/allWeb', :total_call_time => 'externalDuration')
      map_metric('External/allWeb', :call_count => 'externalCallCount')

      # Background Metrics
      map_metric('External/allOther', :total_call_time => 'externalDuration')
      map_metric('External/allOther', :call_count => 'externalCallCount')
    end
  end
end
