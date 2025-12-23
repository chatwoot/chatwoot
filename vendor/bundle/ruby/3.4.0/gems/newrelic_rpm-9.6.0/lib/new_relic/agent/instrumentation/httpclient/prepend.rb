# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

module NewRelic::Agent::Instrumentation
  module HTTPClient
    module Prepend
      include NewRelic::Agent::Instrumentation::HTTPClient::Instrumentation

      def do_get_block(req, proxy, conn, &block)
        with_tracing(req, conn) { super }
      end
    end
  end
end
