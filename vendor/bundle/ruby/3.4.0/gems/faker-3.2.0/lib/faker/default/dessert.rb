# frozen_string_literal: true

module Faker
  class Dessert < Base
    flexible :dessert

    class << self
      ##
      # Produces the name of a dessert variety.
      #
      # @return [String]
      #
      # @example
      #   Faker::Dessert.variety #=> "Cake"
      #
      # @faker.version 1.8.0
      def variety
        fetch('dessert.variety')
      end

      ##
      # Produces the name of a dessert topping.
      #
      # @return [String]
      #
      # @example
      #   Faker::Dessert.topping #=> "Gummy Bears"
      #
      # @faker.version 1.8.0
      def topping
        fetch('dessert.topping')
      end

      ##
      # Produces the name of a dessert flavor.
      #
      # @return [String]
      #
      # @example
      #   Faker::Dessert.flavor #=> "Salted Caramel"
      #
      # @faker.version 1.8.0
      def flavor
        fetch('dessert.flavor')
      end
    end
  end
end
