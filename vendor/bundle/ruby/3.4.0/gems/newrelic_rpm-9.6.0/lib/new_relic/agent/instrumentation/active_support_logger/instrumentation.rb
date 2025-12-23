# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

module NewRelic
  module Agent
    module Instrumentation
      module ActiveSupportLogger
        INSTRUMENTATION_NAME = NewRelic::Agent.base_name(name)

        # Mark @skip_instrumenting on any broadcasted loggers to instrument Rails.logger only
        def broadcast_with_tracing(logger)
          NewRelic::Agent.record_instrumentation_invocation(INSTRUMENTATION_NAME)

          NewRelic::Agent::Instrumentation::Logger.mark_skip_instrumenting(logger)
          yield
        rescue => error
          NewRelic::Agent.notice_error(error)
          raise
        end
      end
    end
  end
end
