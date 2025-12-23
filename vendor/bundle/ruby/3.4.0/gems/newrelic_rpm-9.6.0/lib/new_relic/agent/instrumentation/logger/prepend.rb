# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

module NewRelic::Agent::Instrumentation
  module Logger::Prepend
    include NewRelic::Agent::Instrumentation::Logger

    def format_message(severity, datetime, progname, msg)
      format_message_with_tracing(severity, datetime, progname, msg) { super }
    end
  end
end
