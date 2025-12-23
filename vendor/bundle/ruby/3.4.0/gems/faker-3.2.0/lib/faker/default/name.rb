# frozen_string_literal: true

module Faker
  class Name < Base
    flexible :name

    class << self
      ##
      # Produces a random name.
      #
      # @return [String]
      #
      # @example
      #   Faker::Name.name #=> "Tyshawn Johns Sr."
      #
      # @faker.version 0.9.0
      def name
        parse('name.name')
      end

      ##
      # Produces a random name with middle name.
      #
      # @return [String]
      #
      # @example
      #   Faker::Name.name_with_middle #=> "Aditya Elton Douglas"
      #
      # @faker.version 1.6.4
      def name_with_middle
        parse('name.name_with_middle')
      end

      ##
      # Produces a random first name.
      #
      # @return [String]
      #
      # @example
      #   Faker::Name.first_name #=> "Kaci"
      #
      # @faker.version 0.9.0
      def first_name
        if parse('name.first_name').empty?
          fetch('name.first_name')
        else
          parse('name.first_name')
        end
      end

      ##
      # Produces a random male first name.
      #
      # @return [String]
      #
      # @example
      #   Faker::Name.male_first_name #=> "Edward"
      #
      # @faker.version 1.9.1
      def male_first_name
        fetch('name.male_first_name')
      end
      alias first_name_men male_first_name
      alias masculine_name male_first_name

      ##
      # Produces a random female first name.
      #
      # @return [String]
      #
      # @example
      #   Faker::Name.female_first_name #=> "Natasha"
      #
      # @faker.version 1.9.1
      def female_first_name
        fetch('name.female_first_name')
      end
      alias first_name_women female_first_name
      alias feminine_name female_first_name

      ##
      # Produces a random gender neutral first name.
      #
      # @return [String]
      #
      # @example
      #   Faker::Name.neutral_first_name #=> "Casey"
      #
      # @faker.version 2.13.0
      def neutral_first_name
        fetch('name.neutral_first_name')
      end
      alias first_name_neutral neutral_first_name
      alias gender_neutral_first_name neutral_first_name

      ##
      # Produces a random last name.
      #
      # @return [String]
      #
      # @example
      #   Faker::Name.last_name #=> "Ernser"
      #
      # @faker.version 0.9.0
      def last_name
        parse('name.last_name')
      end
      alias middle_name last_name

      ##
      # Produces a random name prefix.
      #
      # @return [String]
      #
      # @example
      #   Faker::Name.prefix #=> "Mr."
      #
      # @faker.version 0.9.0
      def prefix
        fetch('name.prefix')
      end

      ##
      # Produces a random name suffix.
      #
      # @return [String]
      #
      # @example
      #   Faker::Name.suffix #=> "IV"
      #
      # @faker.version 0.9.0
      def suffix
        fetch('name.suffix')
      end

      ##
      # Produces random initials.
      #
      # @param number [Integer] Number of digits that the generated initials should have.
      # @return [String]
      #
      # @example
      #   Faker::Name.initials            #=> "NJM"
      #   Faker::Name.initials(number: 2) #=> "NM"
      #
      # @faker.version 1.8.5
      def initials(number: 3)
        (0...number).map { rand(65..90).chr }.join
      end
    end
  end
end
