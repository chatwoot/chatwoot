# frozen_string_literal: true

module Faker
  class Boolean < Base
    class << self
      ##
      # Produces a boolean
      #
      # @param true_ratio [Float] The likelihood (as a float, out of 1.0) for the method to return `true`.
      # @return [Boolean]
      #
      # @example
      #   Faker::Boolean.boolean #=> true
      # @example
      #   Faker::Boolean.boolean(true_ratio: 0.2) #=> false
      #
      # @faker.version 1.6.2
      def boolean(true_ratio: 0.5)
        (rand < true_ratio)
      end
    end
  end
end
