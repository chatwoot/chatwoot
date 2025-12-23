# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

# This is the base class for all errors that we want to record through the
# NewRelic::Agent::ErrorCollector#notice_agent_error API. It provides the
# standard support text at the front of the message, and is used for flagging
# agent errors when checking queue limits.

module NewRelic
  module Agent
    class InternalAgentError < StandardError
      def initialize(msg = nil)
        super("Ruby agent internal error. Please contact support referencing this error.\n #{msg}")
      end
    end
  end
end
