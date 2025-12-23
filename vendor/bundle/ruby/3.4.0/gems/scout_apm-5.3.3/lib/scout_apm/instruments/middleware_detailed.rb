# Inserts a new middleware between each actual middleware in the application,
# so as to trace the time for each one.
#
# Currently disabled by default due to the overhead of this approach (~10-15ms
# per request in practice).  Instead, middleware as a whole are instrumented
# via the MiddlewareSummary class.
#
# Turn this on with the configuration setting `detailed_middleware` set to true
module ScoutApm
  module Instruments
    class MiddlewareDetailed
      attr_reader :context

      def initialize(context)
        @context = context
        @installed = false
      end

      def logger
        context.logger
      end

      def installed?
        @installed
      end

      def install(prepend:)
        if defined?(ActionDispatch) && defined?(ActionDispatch::MiddlewareStack) && defined?(ActionDispatch::MiddlewareStack::Middleware)
          @installed = true

          ActionDispatch::MiddlewareStack::Middleware.class_eval do
            def build(app)
              ScoutApm::Agent.instance.context.logger.info("Instrumenting Middleware #{klass.name}")
              new_mw = klass.new(app, *args, &block)
              MiddlewareWrapper.new(new_mw, klass.name)
            end
          end
        end
      end

      class MiddlewareWrapper
        def initialize(app, name)
          @app = app
          @type = "Middleware"
          @name = name
        end

        def call(env)
          req = ScoutApm::RequestManager.lookup
          req.start_layer( ScoutApm::Layer.new(@type, @name) )
          @app.call(env)
        ensure
          req.stop_layer
        end
      end
    end
  end
end
