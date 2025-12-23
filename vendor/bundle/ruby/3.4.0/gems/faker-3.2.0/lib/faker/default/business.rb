# frozen_string_literal: true

require 'date'

module Faker
  class Business < Base
    flexible :business

    class << self
      ##
      # Produces a credit card number.
      #
      # @return [String]
      #
      # @example
      #   Faker::Business.credit_card_number #=> "1228-1221-1221-1431"
      #
      # @faker.version 1.2.0
      def credit_card_number
        fetch('business.credit_card_numbers')
      end

      ##
      # Produces a credit card expiration date.
      #
      # @return [Date]
      #
      # @example
      #   Faker::Business.credit_card_expiry_date #=> <Date: 2015-11-11 ((2457338j,0s,0n),+0s,2299161j)>
      #
      # @faker.version 1.2.0
      def credit_card_expiry_date
        ::Date.today + (365 * rand(1..4))
      end

      ##
      # Produces a type of credit card.
      #
      # @return [String]
      #
      # @example
      #   Faker::Business.credit_card_type #=> "visa"
      #
      # @faker.version 1.2.0
      def credit_card_type
        fetch('business.credit_card_types')
      end
    end
  end
end
