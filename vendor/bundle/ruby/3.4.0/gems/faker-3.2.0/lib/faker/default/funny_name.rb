# frozen_string_literal: true

module Faker
  class FunnyName < Base
    flexible :funny_name

    class << self
      ##
      # Retrieves a funny name.
      #
      # @return [String]
      #
      # @example
      #   Faker::FunnyName.name #=> "Sam Pull"
      #
      # @faker.version 1.8.0
      def name
        fetch('funny_name.name')
      end

      ##
      # Retrieves a funny two word name.
      #
      # @return [String]
      #
      # @example
      #   Faker::FunnyName.two_word_name #=> "Shirley Knot"
      #
      # @faker.version 1.8.0
      def two_word_name
        two_word_names = fetch_all('funny_name.name').select do |name|
          name.count(' ') == 1
        end

        sample(two_word_names)
      end

      ##
      # Retrieves a funny three word name.
      #
      # @return [String]
      #
      # @example
      #   Faker::FunnyName.three_word_name #=> "Carson O. Gin"
      #
      # @faker.version 1.8.0
      def three_word_name
        three_word_names = fetch_all('funny_name.name').select do |name|
          name.count(' ') == 2
        end

        sample(three_word_names)
      end

      ##
      # Retrieves a funny four word name.
      #
      # @return [String]
      #
      # @example
      #   Faker::FunnyName.four_word_name #=> "Maude L. T. Ford"
      #
      # @faker.version 1.8.0
      def four_word_name
        four_word_names = fetch_all('funny_name.name').select do |name|
          name.count(' ') == 3
        end

        sample(four_word_names)
      end

      ##
      # Retrieves a funny name with an initial.
      #
      # @return [String]
      #
      # @example
      #   Faker::FunnyName.name_with_initial #=> "Heather N. Yonn"
      #
      # @faker.version 1.8.0
      def name_with_initial
        names_with_initials = fetch_all('funny_name.name').select do |name|
          name.count('.').positive?
        end

        sample(names_with_initials)
      end
    end
  end
end
