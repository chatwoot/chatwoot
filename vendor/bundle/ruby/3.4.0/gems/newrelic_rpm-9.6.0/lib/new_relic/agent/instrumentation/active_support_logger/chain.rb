# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

module NewRelic::Agent::Instrumentation
  module ActiveSupportLogger
    module Chain
      def instrument!
        ::ActiveSupport::Logger.module_eval do
          include NewRelic::Agent::Instrumentation::ActiveSupportLogger
          def broadcast_with_new_relic(logger)
            broadcast_with_tracing(logger) {
              broadcast_without_newrelic(logger)
            }
          end

          alias broadcast_without_newrelic broadcast
          alias broadcast broadcast_with_new_relic
        end
      end
    end
  end
end
