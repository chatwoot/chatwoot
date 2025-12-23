# frozen_string_literal: true

module Faker
  class Adjective < Base
    flexible :adjective

    class << self
      ##
      # Produces a positive adjective.
      #
      # @return [String]
      #
      # @example
      #   Faker::Adjective.positive #=> "Kind"
      #
      # @faker.version next
      def positive
        fetch('adjective.positive')
      end

      ##
      # Produces a negative adjective.
      #
      # @return [String]
      #
      # @example
      #   Faker::Adjective.negative #=> "Creepy"
      #
      # @faker.version next
      def negative
        fetch('adjective.negative')
      end
    end
  end
end
