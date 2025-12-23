# frozen_string_literal: true

require_relative '../../../tracing/contrib'

require_relative '../../response'
require_relative '../rack/request_middleware'
require_relative 'framework'
require_relative 'gateway/watcher'
require_relative 'gateway/route_params'
require_relative 'gateway/request'
require_relative '../../../tracing/contrib/sinatra/framework'

module Datadog
  module AppSec
    module Contrib
      module Sinatra
        # Set tracer configuration at a late enough time
        module AppSecSetupPatch
          def setup_middleware(*args, &block)
            super.tap do
              Datadog::AppSec::Contrib::Sinatra::Framework.setup
            end
          end
        end

        # Hook into builder before the middleware list gets frozen
        module DefaultMiddlewarePatch
          def setup_middleware(*args, &block)
            builder = args.first

            super.tap do
              tracing_sinatra_framework = Datadog::Tracing::Contrib::Sinatra::Framework
              tracing_middleware = Datadog::Tracing::Contrib::Rack::TraceMiddleware

              if tracing_sinatra_framework.include_middleware?(tracing_middleware, builder)
                tracing_sinatra_framework.add_middleware_after(
                  tracing_middleware,
                  Datadog::AppSec::Contrib::Rack::RequestMiddleware,
                  builder
                )
              else
                tracing_sinatra_framework.add_middleware(Datadog::AppSec::Contrib::Rack::RequestMiddleware, builder)
              end

              tracing_sinatra_framework.inspect_middlewares(builder)
            end
          end
        end

        # Hook into Base#dispatch!, which encompasses route filters
        module DispatchPatch
          def dispatch!
            env = @request.env

            context = env[Datadog::AppSec::Ext::CONTEXT_KEY]

            return super unless context

            # TODO: handle exceptions, except for super

            gateway_request = Gateway::Request.new(env)

            request_return, _gateway_request = Instrumentation.gateway.push('sinatra.request.dispatch', gateway_request) do
              super
            end

            request_return
          end
        end

        # Hook into Base#route_eval, which
        # path params are returned by pattern.params in process_route, then
        # merged with normal params, so we get both
        module RoutePatch
          def process_route(*)
            env = @request.env

            context = env[Datadog::AppSec::Ext::CONTEXT_KEY]

            return super unless context

            # process_route is called repeatedly until a route is found.
            # Until then, params has no route params.
            # Capture normal params.
            base_params = params

            super do |*args|
              # This block is called only once the route is found.
              # At this point params has both route params and normal params.
              route_params = params.each.with_object({}) { |(k, v), h| h[k] = v unless base_params.key?(k) }

              gateway_request = Gateway::Request.new(env)
              gateway_route_params = Gateway::RouteParams.new(route_params)

              Instrumentation.gateway.push('sinatra.request.routed', [gateway_request, gateway_route_params])

              yield(*args)
            end
          end
        end

        # Patcher for AppSec on Sinatra
        module Patcher
          module_function

          def patched?
            Patcher.instance_variable_get(:@patched)
          end

          def target_version
            Integration.version
          end

          def patch
            Gateway::Watcher.watch
            patch_default_middlewares
            patch_dispatch
            patch_route
            setup_security
            Patcher.instance_variable_set(:@patched, true)
          end

          def setup_security
            ::Sinatra::Base.singleton_class.prepend(AppSecSetupPatch)
          end

          def patch_default_middlewares
            ::Sinatra::Base.singleton_class.prepend(DefaultMiddlewarePatch)
          end

          def patch_dispatch
            ::Sinatra::Base.prepend(DispatchPatch)
          end

          def patch_route
            ::Sinatra::Base.prepend(RoutePatch)
          end
        end
      end
    end
  end
end
