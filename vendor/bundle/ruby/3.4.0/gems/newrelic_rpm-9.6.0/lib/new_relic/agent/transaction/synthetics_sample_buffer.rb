# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

require 'new_relic/agent/transaction/transaction_sample_buffer'

module NewRelic
  module Agent
    class Transaction
      class SyntheticsSampleBuffer < TransactionSampleBuffer
        def capacity
          NewRelic::Agent.config[:'synthetics.traces_limit']
        end

        def allow_sample?(sample)
          !sample.synthetics_resource_id.nil?
        end

        def truncate_samples
          @samples.slice!(max_capacity..-1)
        end
      end
    end
  end
end
