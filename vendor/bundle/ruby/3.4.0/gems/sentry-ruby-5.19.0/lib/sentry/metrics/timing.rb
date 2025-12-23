# frozen_string_literal: true

module Sentry
  module Metrics
    module Timing
      class << self
        def nanosecond
          time = Sentry.utc_now
          time.to_i * (10 ** 9) + time.nsec
        end

        def microsecond
          time = Sentry.utc_now
          time.to_i * (10 ** 6) + time.usec
        end

        def millisecond
          Sentry.utc_now.to_i * (10 ** 3)
        end

        def second
          Sentry.utc_now.to_i
        end

        def minute
          Sentry.utc_now.to_i / 60.0
        end

        def hour
          Sentry.utc_now.to_i / 3600.0
        end

        def day
          Sentry.utc_now.to_i / (3600.0 * 24.0)
        end

        def week
          Sentry.utc_now.to_i / (3600.0 * 24.0 * 7.0)
        end
      end
    end
  end
end
