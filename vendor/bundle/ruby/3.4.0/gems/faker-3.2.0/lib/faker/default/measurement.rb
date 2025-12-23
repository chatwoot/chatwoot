# frozen_string_literal: true

module Faker
  class Measurement < Base
    class << self
      ALL = 'all'
      NONE = 'none'

      ##
      # Produces a random height measurement.
      #
      # @param amount [Integer] Specifies the random height value.
      # @return [String]
      #
      # @example
      #   Faker::Measurement.height #=> "6 inches"
      #   Faker::Measurement.height(amount: 1.4) #=> "1.4 inches"
      #   Faker::Measurement.height(amount: "none") #=> "inch"
      #   Faker::Measurement.height(amount: "all") #=> "inches"
      #
      # @faker.version 1.7.3
      def height(amount: rand(10))
        define_measurement_locale(amount, 'height')
      end

      ##
      # Produces a random length measurement.
      #
      # @param amount [Integer] Specifies the random length value.
      # @return [String]
      #
      # @example
      #   Faker::Measurement.length #=> "1 yard"
      #   Faker::Measurement.length(amount: 1.4) #=> "1.4 yards"
      #
      # @faker.version 1.7.3
      def length(amount: rand(10))
        define_measurement_locale(amount, 'length')
      end

      ##
      # Produces a random volume measurement.
      #
      # @param amount [Integer] Specifies the random volume value.
      # @return [String]
      #
      # @example
      #   Faker::Measurement.volume #=> "10 cups"
      #   Faker::Measurement.volume(amount: 1.4) #=> "1.4 cups"
      #
      # @faker.version 1.7.3
      def volume(amount: rand(10))
        define_measurement_locale(amount, 'volume')
      end

      ##
      # Produces a random weight measurement.
      #
      # @param amount [Integer] Specifies the random weight value.
      # @return [String]
      #
      # @example
      #   Faker::Measurement.weight #=> "3 pounds"
      #   Faker::Measurement.weight(amount: 1.4) #=> "1.4 pounds"
      #
      # @faker.version 1.7.3
      def weight(amount: rand(10))
        define_measurement_locale(amount, 'weight')
      end

      ##
      # Produces a random metric height measurement.
      #
      # @param amount [Integer] Specifies the random height value.
      # @return [String]
      #
      # @example
      #   Faker::Measurement.metric_height #=> "2 meters"
      #   Faker::Measurement.metric_height(amount: 1.4) #=> "1.4 meters"
      #
      # @faker.version 1.7.3
      def metric_height(amount: rand(10))
        define_measurement_locale(amount, 'metric_height')
      end

      ##
      # Produces a random metric length measurement.
      #
      # @param amount [Integer] Specifies the random length value.
      # @return [String]
      #
      # @example
      #   Faker::Measurement.metric_length #=> "0 decimeters"
      #   Faker::Measurement.metric_length(amount: 1.4) #=> "1.4 decimeters"
      #
      # @faker.version 1.7.3
      def metric_length(amount: rand(10))
        define_measurement_locale(amount, 'metric_length')
      end

      ##
      # Produces a random metric volume measurement.
      #
      # @param amount [Integer] Specifies the random volume value.
      # @return [String]
      #
      # @example
      #   Faker::Measurement.metric_volume #=> "1 liter"
      #   Faker::Measurement.metric_volume(amount: 1.4) #=> "1.4 liters"
      #
      # @faker.version 1.7.3
      def metric_volume(amount: rand(10))
        define_measurement_locale(amount, 'metric_volume')
      end

      ##
      # Produces a random metric weight measurement.
      #
      # @param amount [Integer] Specifies the random weight value.
      # @return [String]
      #
      # @example
      #   Faker::Measurement.metric_weight #=> "8 grams"
      #   Faker::Measurement.metric_weight(amount: 1.4) #=> "1.4 grams"
      #
      # @faker.version 1.7.3
      def metric_weight(amount: rand(10))
        define_measurement_locale(amount, 'metric_weight')
      end

      private

      def check_for_plural(text, number)
        if number && number != 1
          make_plural(text)
        else
          text
        end
      end

      def define_measurement_locale(amount, locale)
        ensure_valid_amount(amount)
        case amount
        when ALL
          make_plural(fetch("measurement.#{locale}"))
        when NONE
          fetch("measurement.#{locale}")
        else
          locale = check_for_plural(fetch("measurement.#{locale}"), amount)

          "#{amount} #{locale}"
        end
      end

      def ensure_valid_amount(amount)
        raise ArgumentError, 'invalid amount' unless amount == NONE || amount == ALL || amount.is_a?(Integer) || amount.is_a?(Float)
      end

      def make_plural(text)
        case text
        when 'foot'
          'feet'
        when 'inch'
          'inches'
        when 'fluid ounce'
          'fluid ounces'
        when 'metric ton'
          'metric tons'
        else
          "#{text}s"
        end
      end
    end
  end
end
