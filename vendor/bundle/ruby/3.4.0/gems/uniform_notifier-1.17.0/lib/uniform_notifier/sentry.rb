# frozen_string_literal: true

class UniformNotifier
  class SentryNotifier < Base
    class << self
      def active?
        !!UniformNotifier.sentry
      end

      protected

      def _out_of_channel_notify(data)
        message = data.values.compact.join("\n")

        opt = {}
        opt = UniformNotifier.sentry if UniformNotifier.sentry.is_a?(Hash)

        exception = Exception.new(message)
        Sentry.capture_exception(exception, **opt)
      end
    end
  end
end
