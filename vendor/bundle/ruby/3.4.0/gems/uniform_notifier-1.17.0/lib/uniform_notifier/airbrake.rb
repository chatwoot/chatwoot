# frozen_string_literal: true

class UniformNotifier
  class AirbrakeNotifier < Base
    class << self
      def active?
        !!UniformNotifier.airbrake
      end

      protected

      def _out_of_channel_notify(data)
        message = data.values.compact.join("\n")

        opt = {}
        opt = UniformNotifier.airbrake if UniformNotifier.airbrake.is_a?(Hash)

        exception = Exception.new(message)
        Airbrake.notify(exception, opt)
      end
    end
  end
end
