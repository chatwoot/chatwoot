# frozen_string_literal: true

class UniformNotifier
  class RollbarNotifier < Base
    DEFAULT_LEVEL = 'info'

    class << self
      def active?
        !!UniformNotifier.rollbar
      end

      protected

      def _out_of_channel_notify(data)
        message = data.values.compact.join("\n")

        exception = Exception.new(message)
        level = UniformNotifier.rollbar.fetch(:level, DEFAULT_LEVEL) if UniformNotifier.rollbar.is_a?(Hash)
        level ||= DEFAULT_LEVEL

        Rollbar.log(level, exception)
      end
    end
  end
end
