module Sentry
  module Rails
    module InstrumentPayloadCleanupHelper
      IGNORED_DATA_TYPES = [:request, :response, :headers, :exception, :exception_object, Tracing::START_TIMESTAMP_NAME]

      def cleanup_data(data)
        IGNORED_DATA_TYPES.each do |key|
          data.delete(key) if data.key?(key)
        end
      end
    end
  end
end
