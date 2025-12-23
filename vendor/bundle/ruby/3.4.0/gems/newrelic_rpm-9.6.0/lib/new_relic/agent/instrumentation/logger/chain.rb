# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

module NewRelic::Agent::Instrumentation
  module Logger
    def self.instrument!
      ::Logger.class_eval do
        include NewRelic::Agent::Instrumentation::Logger

        alias_method(:format_message_without_new_relic, :format_message)

        def format_message(severity, datetime, progname, msg)
          format_message_with_tracing(severity, datetime, progname, msg) do
            format_message_without_new_relic(severity, datetime, progname, msg)
          end
        end
      end
    end
  end
end
