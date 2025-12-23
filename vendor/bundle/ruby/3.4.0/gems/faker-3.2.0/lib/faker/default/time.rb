# frozen_string_literal: true

module Faker
  class Time < Base
    TIME_RANGES = {
      all: (0..23),
      day: (9..17),
      night: (18..23),
      morning: (6..11),
      afternoon: (12..17),
      evening: (17..21),
      midnight: (0..4)
    }.freeze

    class << self
      ##
      # Produce a random time between two times.
      #
      # @param from [Time, Date, DateTime] The start of the usable time range.
      # @param to [Time, Date, DateTime] The end of the usable time range.
      # @param format [Symbol] The name of a DateTime format to use.
      # @return [Time]
      #
      # @example
      #   # Random Stringified time between two times, formatted to the specified I18n format
      #   # (Examples are from a Rails console with rails-i18n 5.1.1 defaults loaded)
      #   I18n.locale = 'en-US'
      #   Faker::Time.between(from: DateTime.now - 1, to: DateTime.now, format: :default) #=> "Tue, 16 Oct 2018 10:48:27 AM -05:00"
      #   Faker::Time.between(from: DateTime.now - 1, to: DateTime.now, format: :short) #=> "15 Oct 10:48 AM"
      #   Faker::Time.between(from: DateTime.now - 1, to: DateTime.now, format: :long) #=> "October 15, 2018 10:48 AM"
      #
      #   I18n.locale = 'ja'
      #   Faker::Time.between(from: DateTime.now - 1, to: DateTime.now, format: :default) #=> "2018/10/15 10:48:27"
      #   Faker::Time.between(from: DateTime.now - 1, to: DateTime.now, format: :short) #=> "18/10/15 10:48"
      #   Faker::Time.between(from: DateTime.now - 1, to: DateTime.now, format: :long) #=> "2018年10月16日(火) 10時48分27秒 -0500"
      #
      # @faker.version 1.5.0
      def between(from:, to:, format: nil)
        from = get_time_object(from)
        to = get_time_object(to)

        time = Faker::Base.rand_in_range(from, to)
        time_with_format(time, format)
      end

      ##
      # Produce a random time between two dates.
      #
      # @param from [Date] The start of the usable time range.
      # @param to [Date] The end of the usable time range.
      # @param period [Symbol] The time of day, if any. See {TIME_RANGES}.
      # @param format [Symbol] The name of a DateTime format to use.
      # @return [Time]
      #
      # @example
      #   Faker::Time.between_dates(from: Date.today - 1, to: Date.today, period: :all)
      #     #=> "2014-09-19 07:03:30 -0700"
      #   Faker::Time.between_dates(from: Date.today - 1, to: Date.today, period: :day)
      #     #=> "2014-09-18 16:28:13 -0700"
      #   Faker::Time.between_dates(from: Date.today - 1, to: Date.today, period: :night)
      #     #=> "2014-09-20 19:39:38 -0700"
      #   Faker::Time.between_dates(from: Date.today - 1, to: Date.today, period: :morning)
      #     #=> "2014-09-19 08:07:52 -0700"
      #   Faker::Time.between_dates(from: Date.today - 1, to: Date.today, period: :afternoon)
      #     #=> "2014-09-18 12:10:34 -0700"
      #   Faker::Time.between_dates(from: Date.today - 1, to: Date.today, period: :evening)
      #     #=> "2014-09-19 20:21:03 -0700"
      #   Faker::Time.between_dates(from: Date.today - 1, to: Date.today, period: :midnight)
      #     #=> "2014-09-20 00:40:14 -0700"
      #   Faker::Time.between_dates(from: Date.today - 5, to: Date.today + 5, period: :afternoon, format: :default)
      #     #=> "Fri, 19 Oct 2018 15:17:46 -0500"
      #
      # @faker.version 1.0.0
      def between_dates(from:, to:, period: :all, format: nil)
        date = Faker::Date.between(from: from, to: to)
        time = date_with_random_time(date, period)
        time_with_format(time, format)
      end

      ##
      # Produce a random time in the future (up to N days).
      #
      # @param days [Integer] The maximum number of days to go into the future.
      # @param period [Symbol] The time of day, if any. See {TIME_RANGES}.
      # @param format [Symbol] The name of a DateTime format to use.
      # @return [Time]
      #
      # @example
      #   Faker::Time.forward(days: 23, period: :morning)
      #     # => "2014-09-26 06:54:47 -0700"
      #   Faker::Time.forward(days: 5,  period: :evening, format: :long)
      #     #=> "October 21, 2018 20:47"
      #
      # @faker.version 1.5.0
      def forward(days: 365, period: :all, format: nil)
        time_with_format(date_with_random_time(Faker::Date.forward(days: days), period), format)
      end

      ##
      # Produce a random time in the past (up to N days).
      #
      # @param days [Integer] The maximum number of days to go into the past.
      # @param period [Symbol] The time of day, if any. See {TIME_RANGES}.
      # @param format [Symbol] The name of a DateTime format to use.
      # @return [Time]
      #
      # @example
      #   Faker::Time.backward(days: 14, period: :evening)
      #     #=> "2014-09-17 19:56:33 -0700"
      #   Faker::Time.backward(days: 5, period: :morning, format: :short)
      #     #=> "14 Oct 07:44"
      #
      # @faker.version 1.5.0
      def backward(days: 365, period: :all, format: nil)
        time_with_format(date_with_random_time(Faker::Date.backward(days: days), period), format)
      end

      private

      def date_with_random_time(date, period)
        ::Time.local(date.year, date.month, date.day, hours(period), minutes, seconds)
      end

      def time_with_format(time, format)
        format.nil? ? time : I18n.localize(time, format: format)
      end

      def hours(period)
        raise ArgumentError, 'invalid period' unless TIME_RANGES.key? period

        sample(TIME_RANGES[period].to_a)
      end

      def minutes
        seconds
      end

      def seconds
        sample((0..59).to_a)
      end

      def get_time_object(time)
        time = ::Time.parse(time) if time.is_a? String
        time = time.to_time if time.respond_to?(:to_time)
        time
      end
    end
  end
end
