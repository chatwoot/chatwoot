# frozen_string_literal: true

class UniformNotifier
  class OpenTelemetryNotifier < Base
    class << self
      def active?
        !!UniformNotifier.opentelemetry
      end

      protected

      def _out_of_channel_notify(data)
        message = data.values.compact.join("\n")

        exception = Exception.new(message)
        current_span = OpenTelemetry::Trace.current_span
        current_span.record_exception(exception)
      end
    end
  end
end
