# frozen_string_literal: true

module Faker
  class GreekPhilosophers < Base
    class << self
      ##
      # Produces the name of a Greek philosopher.
      #
      # @return [String]
      #
      # @example
      #   Faker::GreekPhilosophers.name #=> "Socrates"
      #
      # @faker.version 1.9.0
      def name
        fetch('greek_philosophers.names')
      end

      ##
      # Produces a quote from a Greek philosopher.
      #
      # @return [String]
      #
      # @example
      #   Faker::GreekPhilosophers.quote #=> "Only the educated are free."
      #
      # @faker.version 1.9.0
      def quote
        fetch('greek_philosophers.quotes')
      end
    end
  end
end
