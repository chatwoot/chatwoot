# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

module NewRelic::Agent::Instrumentation
  module RedisClient
    module Middleware
      # This module is used to instrument Redis 5.x+
      include NewRelic::Agent::Instrumentation::Redis

      def call_pipelined(*args, &block)
        call_pipelined_with_tracing(args[0]) { super }
      end
    end
  end
end
