# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

require 'new_relic/agent/transaction/transaction_sample_buffer'

module NewRelic
  module Agent
    class Transaction
      class SlowestSampleBuffer < TransactionSampleBuffer
        CAPACITY = 1

        def capacity
          CAPACITY
        end

        def allow_sample?(sample)
          sample.threshold && sample.duration >= sample.threshold
        end
      end
    end
  end
end
