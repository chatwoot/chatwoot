# frozen_string_literal: true

module Faker
  class Compass < Base
    class << self
      ##
      # Produces a random cardinal.
      #
      # @return [String]
      #
      # @example
      #   Faker::Compass.cardinal #=> "north"
      #
      # @faker.version 1.8.0
      def cardinal
        fetch('compass.cardinal.word')
      end

      ##
      # Produces a random ordinal.
      #
      # @return [String]
      #
      # @example
      #   Faker::Compass.ordinal #=> "northwest"
      #
      # @faker.version 1.8.0
      def ordinal
        fetch('compass.ordinal.word')
      end

      ##
      # Produces a random half wind.
      #
      # @return [String]
      #
      # @example
      #   Faker::Compass.half_wind #=> "north-northwest"
      #
      # @faker.version 1.8.0
      def half_wind
        fetch('compass.half-wind.word')
      end

      ##
      # Produces a random quarter wind.
      #
      # @return [String]
      #
      # @example
      #   Faker::Compass.quarter_wind #=> "north by west"
      #
      # @faker.version 1.8.0
      def quarter_wind
        fetch('compass.quarter-wind.word')
      end

      ##
      # Produces a random direction.
      #
      # @return [String]
      #
      # @example
      #   Faker::Compass.direction #=> "southeast"
      #
      # @faker.version 1.8.0
      def direction
        parse('compass.direction')
      end

      ##
      # Produces a random abbreviation.
      #
      # @return [String]
      #
      # @example
      #   Faker::Compass.abbreviation #=> "NEbN"
      #
      # @faker.version 1.8.0
      def abbreviation
        parse('compass.abbreviation')
      end

      ##
      # Produces a random azimuth.
      #
      # @return [String]
      #
      # @example
      #   Faker::Compass.azimuth #=> "168.75"
      #
      # @faker.version 1.8.0
      def azimuth
        parse('compass.azimuth')
      end

      ##
      # Produces a random cardinal abbreviation.
      #
      # @return [String]
      #
      # @example
      #   Faker::Compass.cardinal_abbreviation #=> "N"
      #
      # @faker.version 1.8.0
      def cardinal_abbreviation
        fetch('compass.cardinal.abbreviation')
      end

      ##
      # Produces a random ordinal abbreviation.
      #
      # @return [String]
      #
      # @example
      #   Faker::Compass.ordinal_abbreviation #=> "SW"
      #
      # @faker.version 1.8.0
      def ordinal_abbreviation
        fetch('compass.ordinal.abbreviation')
      end

      ##
      # Produces a random half wind abbreviation.
      #
      # @return [String]
      #
      # @example
      #   Faker::Compass.half_wind_abbreviation #=> "NNE"
      #
      # @faker.version 1.8.0
      def half_wind_abbreviation
        fetch('compass.half-wind.abbreviation')
      end

      ##
      # Produces a random quarter wind abbreviation.
      #
      # @return [String]
      #
      # @example
      #   Faker::Compass.quarter_wind_abbreviation #=> "SWbS"
      #
      # @faker.version 1.8.0
      def quarter_wind_abbreviation
        fetch('compass.quarter-wind.abbreviation')
      end

      ##
      # Produces a random cardinal azimuth.
      #
      # @return [String]
      #
      # @example
      #   Faker::Compass.cardinal_azimuth #=> "90"
      #
      # @faker.version 1.8.0
      def cardinal_azimuth
        fetch('compass.cardinal.azimuth')
      end

      ##
      # Produces a random ordinal azimuth.
      #
      # @return [String]
      #
      # @example
      #   Faker::Compass.ordinal_azimuth #=> "135"
      #
      # @faker.version 1.8.0
      def ordinal_azimuth
        fetch('compass.ordinal.azimuth')
      end

      ##
      # Produces a random half wind azimuth.
      #
      # @return [String]
      #
      # @example
      #   Faker::Compass.half_wind_azimuth #=> "292.5"
      #
      # @faker.version 1.8.0
      def half_wind_azimuth
        fetch('compass.half-wind.azimuth')
      end

      ##
      # Produces a random quarter wind azimuth
      #
      # @return [String]
      #
      # @example
      #   Faker::Compass.quarter_wind_azimuth #=> "56.25"
      #
      # @faker.version 1.8.0
      def quarter_wind_azimuth
        fetch('compass.quarter-wind.azimuth')
      end
    end
  end
end
