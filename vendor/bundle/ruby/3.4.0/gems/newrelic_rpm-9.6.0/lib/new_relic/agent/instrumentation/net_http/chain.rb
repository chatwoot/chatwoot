# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

require_relative 'instrumentation'

module NewRelic::Agent::Instrumentation
  module NetHTTP
    module Chain
      def self.instrument!
        Net::HTTP.class_eval do
          include NewRelic::Agent::Instrumentation::NetHTTP

          def request_with_newrelic_trace(request, *args, &block)
            request_with_tracing(request) { request_without_newrelic_trace(request, *args, &block) }
          end

          alias request_without_newrelic_trace request
          alias request request_with_newrelic_trace
        end
      end
    end
  end
end
