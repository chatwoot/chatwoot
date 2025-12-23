# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

module NewRelic
  module Agent
    class CrossAppPayload
      attr_reader :id, :transaction, :referring_guid, :referring_trip_id, :referring_path_hash

      def initialize(id, transaction, transaction_info)
        @id = id
        @transaction = transaction

        transaction_info ||= []
        @referring_guid = transaction_info[0]
        # unused_flag        = transaction_info[1]
        @referring_trip_id = string_or_false_for(transaction_info[2])
        @referring_path_hash = string_or_false_for(transaction_info[3])
      end

      def as_json_array(content_length)
        queue_time_in_seconds = [transaction.queue_time, 0.0].max
        start_time_in_seconds = [transaction.start_time, 0.0].max
        app_time_in_seconds = Process.clock_gettime(Process::CLOCK_REALTIME) - start_time_in_seconds

        [
          NewRelic::Agent.config[:cross_process_id],
          transaction.best_name,
          queue_time_in_seconds,
          app_time_in_seconds,
          content_length,
          transaction.guid,
          false
        ]
      end

      private

      def string_or_false_for(value)
        value.is_a?(String) && value
      end
    end
  end
end
