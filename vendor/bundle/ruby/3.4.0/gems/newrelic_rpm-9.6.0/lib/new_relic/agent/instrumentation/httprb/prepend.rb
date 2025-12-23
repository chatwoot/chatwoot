# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

module NewRelic::Agent::Instrumentation
  module HTTPrb
    module Prepend
      include NewRelic::Agent::Instrumentation::HTTPrb

      def perform(request, options)
        with_tracing(request) { super }
      end
    end
  end
end
