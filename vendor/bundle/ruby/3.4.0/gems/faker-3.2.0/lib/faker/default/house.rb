# frozen_string_literal: true

module Faker
  class House < Base
    class << self
      ##
      # Produces the name of a piece of furniture.
      #
      # @return [String]
      #
      # @example
      #   Faker::House.furniture #=> "chair"
      #
      # @faker.version 1.9.2
      def furniture
        fetch('house.furniture')
      end

      ##
      # Produces the name of a room in a house.
      #
      # @return [String]
      #
      # @example
      #   Faker::House.room #=> "kitchen"
      #
      # @faker.version 1.9.2
      def room
        fetch('house.rooms')
      end
    end
  end
end
