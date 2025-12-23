# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

module NewRelic::Agent::Instrumentation
  module HTTPX
    module Prepend
      include NewRelic::Agent::Instrumentation::HTTPX

      def send_requests(*requests)
        send_requests_with_tracing(*requests) { super }
      end
    end
  end
end
