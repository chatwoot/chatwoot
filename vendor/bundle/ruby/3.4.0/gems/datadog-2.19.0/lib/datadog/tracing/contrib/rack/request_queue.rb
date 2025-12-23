# frozen_string_literal: true

module Datadog
  module Tracing
    module Contrib
      module Rack
        # Retrieves the time spent in an upstream proxy
        # for the current Rack request.
        #
        # This time captures the request delay introduced but
        # such proxy before the request made it to the Ruby
        # process.
        module QueueTime
          REQUEST_START = 'HTTP_X_REQUEST_START'
          QUEUE_START = 'HTTP_X_QUEUE_START'
          MINIMUM_ACCEPTABLE_TIME_VALUE = 1_000_000_000

          module_function

          def get_request_start(env, now = Core::Utils::Time.now.utc)
            header = env[REQUEST_START] || env[QUEUE_START]
            return unless header

            # nginx header is seconds in the format "t=1512379167.574"
            # apache header is microseconds in the format "t=1570633834463123"
            # heroku header is milliseconds in the format "1570634024294"
            time_string = header.to_s.delete('^0-9')
            return if time_string.nil?

            # Return nil if the time is clearly invalid
            time_value = "#{time_string[0, 10]}.#{time_string[10, 6]}".to_f
            return if time_value.zero? || time_value < MINIMUM_ACCEPTABLE_TIME_VALUE

            # return the request_start only if it's lesser than
            # current time, to avoid significant clock skew
            request_start = Time.at(time_value)
            request_start.utc > now ? nil : request_start
          rescue StandardError => e
            # in case of an Exception we don't create a
            # `request.queuing` span
            Datadog.logger.debug("[rack] unable to parse request queue headers: #{e}")
            nil
          end
        end
      end
    end
  end
end
