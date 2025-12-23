# frozen_string_literal: true

module Faker
  class Coin < Base
    class << self
      ##
      # Retrieves a random coin from any country.
      #
      # @return [String]
      #
      # @example
      #   Faker::Coin.name #=> "Brazilian Real"
      #
      # @faker.version 1.9.2
      def name
        fetch('currency.name')
      end

      ##
      # Retrieves a face to a flipped coin
      #
      # @return [String]
      #
      # @example
      #   Faker::Coin.flip #=> "Heads"
      #
      # @faker.version 1.9.2
      def flip
        fetch('coin.flip')
      end
    end
  end
end
