# frozen_string_literal: true

module Sentry
  module Cron
    module MonitorSchedule
      class Crontab
        # A crontab formatted string such as "0 * * * *".
        # @return [String]
        attr_accessor :value

        def initialize(value)
          @value = value
        end

        def to_hash
          { type: :crontab, value: value }
        end
      end

      class Interval
        # The number representing duration of the interval.
        # @return [Integer]
        attr_accessor :value

        # The unit representing duration of the interval.
        # @return [Symbol]
        attr_accessor :unit

        VALID_UNITS = %i[year month week day hour minute]

        def initialize(value, unit)
          @value = value
          @unit = unit
        end

        def to_hash
          { type: :interval, value: value, unit: unit }
        end
      end
    end
  end
end
