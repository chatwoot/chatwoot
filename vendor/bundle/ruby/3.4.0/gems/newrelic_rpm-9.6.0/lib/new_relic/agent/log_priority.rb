# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

require 'new_relic/agent/event_aggregator'

# Stateless calculation of priority for a given log event
module NewRelic
  module Agent
    module LogPriority
      extend self

      def priority_for(txn)
        return txn.priority if txn

        rand.round(NewRelic::PRIORITY_PRECISION)
      end
    end
  end
end
