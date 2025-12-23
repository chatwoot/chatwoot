# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

require 'new_relic/agent/heap'

module NewRelic
  module Agent
    class TimestampSampledBuffer < PrioritySampledBuffer
      TIMESTAMP_KEY = 'timestamp'.freeze

      private

      def priority_for(event)
        -event[0][TIMESTAMP_KEY]
      end
    end
  end
end
