module Sentry
  module Rails
    module ControllerMethods
      def capture_message(message, options = {})
        with_request_scope do
          Sentry::Rails.capture_message(message, **options)
        end
      end

      def capture_exception(exception, options = {})
        with_request_scope do
          Sentry::Rails.capture_exception(exception, **options)
        end
      end

      private

      def with_request_scope
        Sentry.with_scope do |scope|
          scope.set_rack_env(request.env)
          yield
        end
      end
    end
  end
end
