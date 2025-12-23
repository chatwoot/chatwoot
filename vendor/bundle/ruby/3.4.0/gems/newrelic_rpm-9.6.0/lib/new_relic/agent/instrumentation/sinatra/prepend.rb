# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

module NewRelic::Agent::Instrumentation
  module Sinatra
    module Prepend
      include ::NewRelic::Agent::Instrumentation::Sinatra::Tracer

      def dispatch!
        dispatch_with_tracing { super }
      end

      def process_route(*args, &block)
        process_route_with_tracing(*args) { super }
      end

      def route_eval(*args, &block)
        route_eval_with_tracing(*args) { super }
      end
    end

    module Build
      module Prepend
        include ::NewRelic::Agent::Instrumentation::Sinatra::Tracer

        def build(*args, &block)
          build_with_tracing(*args) { super }
        end
      end
    end
  end
end
