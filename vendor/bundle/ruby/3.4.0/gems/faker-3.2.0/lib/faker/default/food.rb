# frozen_string_literal: true

module Faker
  class Food < Base
    flexible :food

    class << self
      ##
      # Retrieves an allergen.
      #
      # @return [String]
      #
      # @example
      #   Faker::Food.allergen #=> "Peanuts"
      #
      # @faker.version next
      def allergen
        fetch('food.allergens')
      end

      ##
      # Retrieves a typical dish from each country.
      #
      # @return [String]
      #
      # @example
      #   Faker::Food.dish #=> "Feijoada"
      #
      # @faker.version 1.8.0
      def dish
        fetch('food.dish')
      end

      ##
      # Retrieves a description about some dish
      #
      # @return [String]
      #
      # @example
      #   Faker::Food.description #=> "Breaded fried chicken with waffles. Served with maple syrup."
      #
      # @faker.version 1.9.0
      def description
        fetch('food.descriptions')
      end

      ##
      # Retrieves an ingredient
      #
      # @return [String]
      #
      # @example
      #   Faker::Food.ingredient #=> "Olives"
      #
      # @faker.version 1.7.0
      def ingredient
        fetch('food.ingredients')
      end

      ##
      # Retrieves a fruit
      #
      # @return [String]
      #
      # @example
      #   Faker::Food.fruits #=> "Papaya"
      #
      # @faker.version 1.9.0
      def fruits
        fetch('food.fruits')
      end

      ##
      # Retrieves a vegetable
      #
      # @return [String]
      #
      # @example
      #   Faker::Food.vegetables #=> "Broccolini"
      #
      # @faker.version 1.9.0
      def vegetables
        fetch('food.vegetables')
      end

      ##
      # Retrieves some random spice
      #
      # @return [String]
      #
      # @example
      #   Faker::Food.spice #=> "Garlic Chips"
      #
      # @faker.version 1.7.0
      def spice
        fetch('food.spices')
      end

      ##
      # Retrieves cooking measures
      #
      # @return [String]
      #
      # @example
      #   Faker::Food.measurement #=> "1/3"
      #
      # @faker.version 1.7.0
      def measurement
        "#{fetch('food.measurement_sizes')} #{fetch('food.measurements')}"
      end

      ##
      # Retrieves metric measurements
      #
      # @return [String]
      #
      # @example
      #   Faker::Food.metric_measurement #=> "centiliter"
      #
      # @faker.version 1.8.3
      def metric_measurement
        fetch('food.metric_measurements')
      end

      ##
      # Retrieves ethnic category
      #
      # @return [String]
      #
      # @example
      #   Faker::Food.ethnic_category #=> "Indian cuisine"
      #
      # @faker.version next
      def ethnic_category
        fetch('food.ethnic_category')
      end
    end
  end
end
