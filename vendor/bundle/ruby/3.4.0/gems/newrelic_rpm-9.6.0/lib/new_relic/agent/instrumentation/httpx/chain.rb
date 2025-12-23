# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

module NewRelic::Agent::Instrumentation
  module HTTPX
    module Chain
      def self.instrument!
        ::HTTPX::Session.class_eval do
          include NewRelic::Agent::Instrumentation::HTTPX

          alias_method(:send_requests_without_tracing, :send_requests)
          def send_requests(*requests)
            send_requests_with_tracing(*requests) { send_requests_without_tracing(*requests) }
          end
        end
      end
    end
  end
end
