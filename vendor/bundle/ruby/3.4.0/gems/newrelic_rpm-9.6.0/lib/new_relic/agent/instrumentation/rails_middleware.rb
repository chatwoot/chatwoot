# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

require 'new_relic/agent/instrumentation/middleware_proxy'

DependencyDetection.defer do
  named :rails_middleware

  depends_on do
    !NewRelic::Agent.config[:disable_middleware_instrumentation]
  end

  depends_on do
    defined?(Rails::VERSION::MAJOR) && Rails::VERSION::MAJOR.to_i >= 3
  end

  executes do
    NewRelic::Agent.logger.info('Installing Rails 3+ middleware instrumentation')
    module ActionDispatch
      class MiddlewareStack
        class Middleware
          def build_with_new_relic(app)
            # MiddlewareProxy.wrap guards against double-wrapping here.
            # We need to instrument the innermost app (usually a RouteSet),
            # which will never itself be the return value from #build, but will
            # instead be the initial value of the app argument.
            wrapped_app = ::NewRelic::Agent::Instrumentation::MiddlewareProxy.wrap(app)
            result = build_without_new_relic(wrapped_app)
            ::NewRelic::Agent::Instrumentation::MiddlewareProxy.wrap(result)
          end

          alias_method :build_without_new_relic, :build
          alias_method :build, :build_with_new_relic
        end
      end
    end
  end
end
