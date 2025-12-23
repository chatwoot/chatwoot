# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

# NewRelic instrumentation for Sinatra applications.  Sinatra actions will
# appear in the UI similar to controller actions, and have breakdown charts
# and transaction traces.
#
# The actions in the UI will correspond to the pattern expression used
# to match them, not directly to full URL's.
module NewRelic::Agent::Instrumentation
  module Sinatra
    module Tracer
      include ::NewRelic::Agent::Instrumentation::ControllerInstrumentation

      INSTRUMENTATION_NAME = 'Sinatra'

      def self.included(clazz)
        clazz.extend(self)
      end

      # Expected method for supporting ControllerInstrumentation
      def newrelic_request_headers(_)
        request.env
      end

      def newrelic_middlewares
        middlewares = [NewRelic::Rack::BrowserMonitoring]
        if NewRelic::Rack::AgentHooks.needed?
          middlewares << NewRelic::Rack::AgentHooks
        end
        middlewares
      end

      def build_with_tracing(*args, &block)
        unless NewRelic::Agent.config[:disable_sinatra_auto_middleware]
          newrelic_middlewares.each do |middleware_class|
            try_to_use(self, middleware_class)
          end
        end
        yield
      end

      def install_lock
        @install_lock ||= Mutex.new
      end

      def try_to_use(app, clazz)
        install_lock.synchronize do
          # The following line needs else branch coverage
          has_middleware = app.middleware && app.middleware.any? { |info| info && info[0] == clazz } # rubocop:disable Style/SafeNavigation
          app.use(clazz) unless has_middleware
        end
      end

      # Capture last route we've seen. Will set for transaction on route_eval
      def process_route_with_tracing(*args)
        begin
          env['newrelic.last_route'] = args[0]
        rescue => e
          ::NewRelic::Agent.logger.debug('Failed determining last route in Sinatra', e)
        end
        yield
      end

      # If a transaction name is already set, this call will tromple over it.
      # This is intentional, as typically passing to a separate route is like
      # an entirely separate transaction, so we pick up the new name.
      #
      # If we're ignored, this remains safe, since set_transaction_name
      # care for the gating on the transaction's existence for us.
      def route_eval_with_tracing(*args)
        begin
          if txn_name = TransactionNamer.transaction_name_for_route(env, request)
            ::NewRelic::Agent::Transaction.set_default_transaction_name(
              "#{self.class.name}/#{txn_name}", :sinatra
            )
          end
        rescue => e
          ::NewRelic::Agent.logger.debug('Failed during route_eval to set transaction name', e)
        end
        yield
      end

      def get_request_params
        begin
          @request.params
        rescue => e
          NewRelic::Agent.logger.debug('Failed to get params from Rack request.', e)
          nil
        end
      end

      def dispatch_with_tracing
        NewRelic::Agent.record_instrumentation_invocation(INSTRUMENTATION_NAME)

        request_params = get_request_params
        filtered_params = ::NewRelic::Agent::ParameterFiltering::apply_filters(request.env, request_params || {})

        name = TransactionNamer.initial_transaction_name(request)
        perform_action_with_newrelic_trace(:category => :sinatra,
          :name => name,
          :params => filtered_params) do
          begin
            yield
          ensure
            # Will only see an error raised if :show_exceptions is true, but
            # will always see them in the env hash if they occur
            had_error = env.has_key?('sinatra.error')
            ::NewRelic::Agent.notice_error(env['sinatra.error']) if had_error
          end
        end
      end

      def do_not_trace?
        Ignorer.should_ignore?(self, :routes)
      end

      # Overrides ControllerInstrumentation implementation
      def ignore_apdex?
        Ignorer.should_ignore?(self, :apdex)
      end

      # Overrides ControllerInstrumentation implementation
      def ignore_enduser?
        Ignorer.should_ignore?(self, :enduser)
      end
    end
  end
end
