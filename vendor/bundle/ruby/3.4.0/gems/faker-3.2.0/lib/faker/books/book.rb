# frozen_string_literal: true

module Faker
  class Book < Base
    flexible :book

    class << self
      ##
      # Produces a random book title
      #
      # @return [String]
      #
      # @example
      #   Faker::Book.title #=> "The Odd Sister"
      #
      # @faker.version 1.9.3
      def title
        fetch('book.title')
      end

      ##
      # Produces a random book author
      #
      # @return [String]
      #
      # @example
      #   Faker::Book.author #=> "Alysha Olsen"
      #
      # @faker.version 1.9.3
      def author
        parse('book.author')
      end

      ##
      # Produces a random book publisher
      #
      # @return [String]
      #
      # @example
      #   Faker::Book.publisher #=> "Opus Reader"
      #
      # @faker.version 1.9.3
      def publisher
        fetch('book.publisher')
      end

      ##
      # Produces a random genre
      #
      # @return [String]
      #
      # @example
      #   Faker::Book.genre #=> "Mystery"
      #
      # @faker.version 1.9.3
      def genre
        fetch('book.genre')
      end
    end
  end
end
