# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

module NewRelic::Agent::Instrumentation
  module HTTPClient
    module Chain
      def self.instrument!
        ::HTTPClient.class_eval do
          include NewRelic::Agent::Instrumentation::HTTPClient::Instrumentation

          def do_get_block_with_newrelic(req, proxy, conn, &block)
            with_tracing(req, conn) do
              do_get_block_without_newrelic(req, proxy, conn, &block)
            end
          end

          alias :do_get_block_without_newrelic :do_get_block
          alias :do_get_block :do_get_block_with_newrelic
        end
      end
    end
  end
end
