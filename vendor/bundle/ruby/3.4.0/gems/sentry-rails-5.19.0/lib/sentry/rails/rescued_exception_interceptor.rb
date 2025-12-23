module Sentry
  module Rails
    class RescuedExceptionInterceptor
      def initialize(app)
        @app = app
      end

      def call(env)
        return @app.call(env) unless Sentry.initialized?

        begin
          @app.call(env)
        rescue => e
          env["sentry.rescued_exception"] = e if report_rescued_exceptions?
          raise e
        end
      end

      def report_rescued_exceptions?
        Sentry.configuration.rails.report_rescued_exceptions
      end
    end
  end
end
