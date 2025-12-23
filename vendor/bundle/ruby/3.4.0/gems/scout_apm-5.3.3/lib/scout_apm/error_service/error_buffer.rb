# Holds onto exceptions, and moves them forward to shipping when appropriate
module ScoutApm
  module ErrorService
    class ErrorBuffer
      include Enumerable

      attr_reader :agent_context

      def initialize(agent_context)
        @agent_context = agent_context
        @error_records = []
        @mutex = Monitor.new
      end

      def capture(exception, env)
        context = ScoutApm::Context.current

        @mutex.synchronize {
          @error_records << ErrorRecord.new(agent_context, exception, env, context)
        }
      end

      def get_and_reset_error_records
        @mutex.synchronize {
          ret = @error_records
          @error_records = []
          ret
        }
      end

      # Enables enumerable - for count and each and similar methods
      def each
        @error_records.each do |error_record|
          yield error_record
        end
      end
    end
  end
end
