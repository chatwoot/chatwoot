# frozen_string_literal: true

module Faker
  class Restaurant < Base
    flexible :restaurant

    class << self
      ##
      # Produces the name of a restaurant.
      #
      # @return [String]
      #
      # @example
      #   Faker::Restaurant.name #=> "Curry King"
      #
      # @faker.version 1.9.2
      def name
        bothify(parse('restaurant.name'))
      end

      ##
      # Produces a type of restaurant.
      #
      # @return [String]
      #
      # @example
      #   Faker::Restaurant.type #=> "Comfort Food"
      #
      # @faker.version 1.9.2
      def type
        fetch('restaurant.type')
      end

      ##
      # Produces a description of a restaurant.
      #
      # @return [String]
      #
      # @example
      #   Faker::Restaurant.description
      #     #=> "We are committed to using the finest ingredients in our recipes. No food leaves our kitchen that we ourselves would not eat."
      #
      # @faker.version 1.9.2
      def description
        fetch('restaurant.description')
      end

      ##
      # Produces a review for a restaurant.
      #
      # @return [String]
      #
      # @example
      #   Faker::Restaurant.review
      #     #=> "Brand new. Great design. Odd to hear pop music in a Mexican establishment. Music is a bit loud. It should be background."
      #
      # @faker.version 1.9.2
      def review
        fetch('restaurant.review')
      end
    end
  end
end
