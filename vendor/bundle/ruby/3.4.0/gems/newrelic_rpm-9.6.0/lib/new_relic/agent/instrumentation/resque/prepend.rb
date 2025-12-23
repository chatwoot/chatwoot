# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

module NewRelic::Agent::Instrumentation
  module Resque
    module Prepend
      include NewRelic::Agent::Instrumentation::Resque

      def perform
        with_tracing { super }
      end
    end
  end
end
