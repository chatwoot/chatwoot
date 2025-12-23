# Inserts a single middleware at the outer edge of the stack (the first
# middleware called, before passing to the rest of the stack) to trace the
# total time spent between all middlewares. This instrument does not attempt to
# allocate time to specific middlewares. (see MiddlewareDetailed)
#
module ScoutApm
  module Instruments
    class MiddlewareSummary
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
        if defined?(ActionDispatch) && defined?(ActionDispatch::MiddlewareStack)
          @installed = true

          logger.info("Instrumenting Middleware")
          ActionDispatch::MiddlewareStack.class_eval do
            def build_with_scout_instruments(app = nil, &block)
              mw_stack = build_without_scout_instruments(app) { block.call if block }
              if app == mw_stack
                # Return the raw middleware stack if it equaled app. No
                # middlewares were created, so nothing to wrap & test.
                #
                # Avoids instrumentation of something that doesn't exist
                mw_stack
              else
                MiddlewareSummaryWrapper.new(mw_stack)
              end
            end

            alias_method :build_without_scout_instruments, :build
            alias_method :build, :build_with_scout_instruments
          end
        end
      end

      class MiddlewareSummaryWrapper
        def initialize(app)
          @app = app
        end

        def call(env)
          req = ScoutApm::RequestManager.lookup
          layer = ScoutApm::Layer.new("Middleware", "Summary")
          req.start_layer(layer)
          @app.call(env)
        ensure
          req.stop_layer
        end

        # Some code (found in resque_web initially) attempts to call methods
        # directly on `MyApplication.app`, which is the middleware stack.
        # If it hits our middleware instead of the object at the root of the
        # app that it expected, then a method it expects will not be there, and an
        # error thrown.
        #
        # Specifically, resque_web assumes `ResqueWeb::Engine.app.url_helpers`
        # is a method call on rails router for its own Engine, when in fact,
        # we've added a middleware before it.
        #
        # So method_missing just proxies anything to the nested @app object
        #
        # While method_missing is not very performant, this is only here to
        # handle edge-cases in other code, and should not be regularly called
        def method_missing(sym, *arguments, &block)
          if @app.respond_to?(sym)
            @app.send(sym, *arguments, &block)
          else
            super
          end
        end

        def respond_to?(sym, include_private = false)
          if @app.respond_to?(sym, include_private)
            true
          else
            super
          end
        end
      end
    end
  end
end
