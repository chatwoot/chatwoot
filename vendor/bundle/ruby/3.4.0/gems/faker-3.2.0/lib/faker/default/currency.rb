# frozen_string_literal: true

module Faker
  class Currency < Base
    class << self
      ##
      # Produces the name of a currency.
      #
      # @return [String]
      #
      # @example
      #   Faker::Currency.name #=> "Swedish Krona"
      #
      # @faker.version 1.9.0
      def name
        fetch('currency.name')
      end

      ##
      # Produces a currency code.
      #
      # @return [String]
      #
      # @example
      #   Faker::Currency.code #=> "USD"
      #
      # @faker.version 1.9.0
      def code
        fetch('currency.code')
      end

      ##
      # Produces a currency symbol.
      #
      # @return [String]
      #
      # @example
      #   Faker::Currency.symbol #=> "$"
      #
      # @faker.version 1.9.0
      def symbol
        fetch('currency.symbol')
      end
    end
  end
end
