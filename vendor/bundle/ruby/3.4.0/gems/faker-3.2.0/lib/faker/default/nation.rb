# frozen_string_literal: true

module Faker
  class Nation < Base
    flexible :nation
    class << self
      ##
      # Produces a random nationality.
      #
      # @return [String]
      #
      # @example
      #   Faker::Nation.nationality #=> "Nepalese"
      #
      # @faker.version 1.9.0
      def nationality
        fetch('nation.nationality')
      end

      ##
      # Produces a random national flag emoji.
      #
      # @return [String]
      #
      # @example
      #   Faker::Nation.flag #=> "🇫🇮"
      #
      # @faker.version 1.9.0
      def flag
        sample(translate('faker.nation.flag')).pack('C*').force_encoding('utf-8')
      end

      ##
      # Produces a random national language.
      #
      # @return [String]
      #
      # @example
      #   Faker::Nation.language #=> "Nepali"
      #
      # @faker.version 1.9.0
      def language
        fetch('nation.language')
      end

      ##
      # Produces a random capital city.
      #
      # @return [String]
      #
      # @example
      #   Faker::Nation.capital_city #=> "Kathmandu"
      #
      # @faker.version 1.9.0
      def capital_city
        fetch('nation.capital_city')
      end

      ##
      # Produces a random national sport.
      #
      # @return [String]
      #
      # @example
      #   Faker::Nation.national_sport #=> "dandi biyo"
      #
      # @faker.version 1.9.0
      def national_sport
        fetch('team.sport')
      end
    end
  end
end
