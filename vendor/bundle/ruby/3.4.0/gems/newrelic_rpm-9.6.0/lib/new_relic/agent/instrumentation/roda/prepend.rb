# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

module NewRelic::Agent::Instrumentation
  module Roda
    module Prepend
      include ::NewRelic::Agent::Instrumentation::Roda::Tracer

      def _roda_handle_main_route(*args)
        _roda_handle_main_route_with_tracing(*args) { super }
      end
    end

    module Build
      module Prepend
        include ::NewRelic::Agent::Instrumentation::Roda::Tracer
        def build_rack_app
          build_rack_app_with_tracing { super }
        end
      end
    end
  end
end
