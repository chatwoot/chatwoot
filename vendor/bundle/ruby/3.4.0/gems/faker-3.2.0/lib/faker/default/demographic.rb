# frozen_string_literal: true

module Faker
  class Demographic < Base
    class << self
      ##
      # Produces the name of a race.
      #
      # @return [String]
      #
      # @example
      #   Faker::Demographic.race #=> "Native Hawaiian or Other Pacific Islander"
      #
      # @faker.version 1.7.3
      def race
        fetch('demographic.race')
      end

      ##
      # Produces a level of educational attainment.
      #
      # @return [String]
      #
      # @example
      #   Faker::Demographic.educational_attainment #=> "GED or alternative credential"
      #
      # @faker.version 1.7.3
      def educational_attainment
        fetch('demographic.educational_attainment')
      end

      ##
      # Produces a denonym.
      #
      # @return [String]
      #
      # @example
      #   Faker::Demographic.denonym #=> "Panamanian"
      #
      # @faker.version 1.7.3
      def demonym
        fetch('demographic.demonym')
      end

      ##
      # Produces a marital status.
      #
      # @return [String]
      #
      # @example
      #   Faker::Demographic.marital_status #=> "Widowed"
      #
      # @faker.version 1.7.3
      def marital_status
        fetch('demographic.marital_status')
      end

      ##
      # Produces a sex for demographic purposes.
      #
      # @return [String]
      #
      # @example
      #   Faker::Demographic.sex #=> "Female"
      #
      # @faker.version 1.7.3
      def sex
        fetch('demographic.sex')
      end

      ##
      # Produces a height as a string.
      #
      # @param unit [Symbol] either `:metric` or `imperial`.
      # @return [String]
      #
      # @example
      #   Faker::Demographic.height #=> "1.61"
      # @example
      #   Faker::Demographic.height(unit: :imperial) #=> "6 ft, 2 in"
      #
      # @faker.version 1.7.3
      def height(unit: :metric)
        case unit
        when :imperial
          inches = rand_in_range(57, 86)
          "#{inches / 12} ft, #{inches % 12} in"
        when :metric
          rand_in_range(1.45, 2.13).round(2).to_s
        end
      end
    end
  end
end
