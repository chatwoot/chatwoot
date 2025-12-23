# frozen_string_literal: true

module Faker
  class Superhero < Base
    class << self
      ##
      # Produces a superpower.
      #
      # @return [String]
      #
      # @example
      #   Faker::Superhero.power #=> "Photokinesis"
      #
      # @faker.version 1.6.2
      def power
        fetch('superhero.power')
      end

      ##
      # Produces a superhero name prefix.
      #
      # @return [String]
      #
      # @example
      #   Faker::Superhero.prefix #=> "the Fated"
      #
      # @faker.version 1.6.2
      def prefix
        fetch('superhero.prefix')
      end

      ##
      # Produces a superhero name suffix.
      #
      # @return [String]
      #
      # @example
      #   Faker::Superhero.suffix #=> "Captain"
      #
      # @faker.version 1.6.2
      def suffix
        fetch('superhero.suffix')
      end

      ##
      # Produces a superhero descriptor.
      #
      # @return [String]
      #
      # @example
      #   Faker::Superhero.descriptor #=> "Bizarro"
      #
      # @faker.version 1.6.2
      def descriptor
        fetch('superhero.descriptor')
      end

      ##
      # Produces a random superhero name.
      #
      # @return [String]
      #
      # @example
      #   Faker::Superhero.name #=> "Magnificent Shatterstar"
      #
      # @faker.version 1.6.2
      def name
        parse('superhero.name')
      end
    end
  end
end
