# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

module NewRelic::Agent::Instrumentation
  module Bunny::Prepend
    module Exchange
      include NewRelic::Agent::Instrumentation::Bunny::Exchange

      def publish(payload, opts = {})
        publish_with_tracing(payload, opts) { super }
      end
    end

    module Queue
      include NewRelic::Agent::Instrumentation::Bunny::Queue

      def pop(opts = {:manual_ack => false}, &block)
        pop_with_tracing { super }
      end

      def purge(*args)
        purge_with_tracing { super }
      end
    end

    module Consumer
      include NewRelic::Agent::Instrumentation::Bunny::Consumer

      def call(*args)
        call_with_tracing(*args) { super }
      end
    end
  end
end
