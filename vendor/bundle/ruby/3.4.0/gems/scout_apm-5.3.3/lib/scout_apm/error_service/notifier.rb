module ScoutApm
  module ErrorService
    class Notifier
      attr_reader :context
      attr_reader :reporter

      def initialize(context)
        @context = context
        @reporter = ScoutApm::Reporter.new(context, :errors)
      end

      def ship
        error_records = context.error_buffer.get_and_reset_error_records
        if error_records.any?
          payload = ScoutApm::ErrorService::Payload.new(context, error_records)
          reporter.report(
            payload.serialize,
            default_headers.merge("X-Error-Count" => error_records.length.to_s)
          )
        end
      end

      private

      def default_headers
        {
          "Content-Type" => "application/json",
          "Accept" => "application/json"
        }
      end
    end
  end
end
