# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

module NewRelic::Agent::Instrumentation
  module Redis
    module Prepend
      include NewRelic::Agent::Instrumentation::Redis

      # Defined in version 5.x+
      def call_v(*args, &block)
        call_with_tracing(args[0]) { super }
      end

      # Defined in version 4.x, 3.x
      def call(*args, &block)
        call_with_tracing(args[0]) { super }
      end

      def call_pipeline(*args, &block)
        call_pipeline_with_tracing(args[0]) { super }
      end

      def connect(*args, &block)
        connect_with_tracing { super }
      end
    end
  end
end
