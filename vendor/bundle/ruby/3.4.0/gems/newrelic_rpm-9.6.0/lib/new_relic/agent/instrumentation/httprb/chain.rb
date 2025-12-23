# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

module NewRelic::Agent::Instrumentation
  module HTTPrb
    module Chain
      def self.instrument!
        ::HTTP::Client.class_eval do
          include NewRelic::Agent::Instrumentation::HTTPrb

          def perform_with_newrelic_trace(request, options)
            with_tracing(request) { perform_without_newrelic_trace(request, options) }
          end

          alias perform_without_newrelic_trace perform
          alias perform perform_with_newrelic_trace
        end
      end
    end
  end
end
