module ScoutApm
  module LayerConverters
    class RequestQueueTimeConverter < ConverterBase

      HEADERS = %w(X-Queue-Start X-Request-Start X-QUEUE-START X-REQUEST-START x-queue-start x-request-start)

      def headers
        request.headers
      end

      def record!
        return unless request.web?

        return unless context.config.value('record_queue_time')

        return unless headers

        raw_start = locate_timestamp
        return unless raw_start

        parsed_start = parse(raw_start)
        return unless parsed_start

        request_start = root_layer.start_time
        queue_time = (request_start - parsed_start).to_f

        # If we end up with a negative value, just bail out and don't report anything
        return if queue_time < 0

        meta = MetricMeta.new("QueueTime/Request", {:scope => scope_layer.legacy_metric_name})
        stat = MetricStats.new(true)
        stat.update!(queue_time)
        metrics = { meta => stat }
        
        @store.track!(metrics)
        metrics  # this result must be returned so it can be accessed by transaction callback extensions
      end

      private

      # Looks through the possible headers with this data, and extracts the raw
      # value of the header
      # Returns nil if not found
      def locate_timestamp
        return nil unless headers

        header = HEADERS.find { |candidate| headers[candidate] }
        if header
          data = headers[header]
          data.to_s.gsub(/(t=|\.)/, '')
        else
          nil
        end
      end

      # Returns a timestamp in fractional seconds since epoch
      def parse(time_string)
        Time.at("#{time_string[0,10]}.#{time_string[10,13]}".to_f)
      end
    end
  end
end
