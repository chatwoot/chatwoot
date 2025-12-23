# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

module NewRelic::Agent::Instrumentation
  module Roda
    module Tracer
      include ::NewRelic::Agent::Instrumentation::ControllerInstrumentation

      INSTRUMENTATION_NAME = 'Roda'

      def self.included(clazz)
        clazz.extend(self)
      end

      def newrelic_middlewares
        middlewares = [NewRelic::Rack::BrowserMonitoring]
        if NewRelic::Rack::AgentHooks.needed?
          middlewares << NewRelic::Rack::AgentHooks
        end
        middlewares
      end

      def build_rack_app_with_tracing
        unless NewRelic::Agent.config[:disable_roda_auto_middleware]
          newrelic_middlewares.each do |middleware_class|
            self.use middleware_class
          end
        end
        yield
      end

      # Roda makes use of Rack, so we can get params from the request object
      def rack_request_params
        begin
          @_request.params
        rescue => e
          NewRelic::Agent.logger.debug('Failed to get params from Rack request.', e)
          NewRelic::EMPTY_HASH
        end
      end

      def _roda_handle_main_route_with_tracing(*args)
        NewRelic::Agent.record_instrumentation_invocation(INSTRUMENTATION_NAME)

        perform_action_with_newrelic_trace(
          category: :roda,
          name: ::NewRelic::Agent::Instrumentation::Roda::TransactionNamer.transaction_name(request),
          params: ::NewRelic::Agent::ParameterFiltering::apply_filters(request.env, rack_request_params)
        ) do
          yield
        end
      end

      def do_not_trace?
        NewRelic::Agent::Instrumentation::Roda::Ignorer.should_ignore?(self, :routes)
      end

      def ignore_apdex?
        NewRelic::Agent::Instrumentation::Roda::Ignorer.should_ignore?(self, :apdex)
      end

      def ignore_enduser?
        NewRelic::Agent::Instrumentation::Roda::Ignorer.should_ignore?(self, :enduser)
      end
    end
  end
end
