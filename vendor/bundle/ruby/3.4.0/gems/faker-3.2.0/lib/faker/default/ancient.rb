# frozen_string_literal: true

module Faker
  class Ancient < Base
    class << self
      ##
      # Produces a god from ancient mythology.
      #
      # @return [String]
      #
      # @example
      #   Faker::Ancient.god #=> "Zeus"
      #
      # @faker.version 1.7.0
      def god
        fetch('ancient.god')
      end

      ##
      # Produces a primordial from ancient mythology.
      #
      # @return [String]
      #
      # @example
      #   Faker::Ancient.primordial #=> "Gaia"
      #
      # @faker.version 1.7.0
      def primordial
        fetch('ancient.primordial')
      end

      ##
      # Produces a titan from ancient mythology.
      #
      # @return [String]
      #
      # @example
      #   Faker::Ancient.titan #=> "Atlas"
      #
      # @faker.version 1.7.0
      def titan
        fetch('ancient.titan')
      end

      ##
      # Produces a hero from ancient mythology.
      #
      # @return [String]
      #
      # @example
      #   Faker::Ancient.hero #=> "Achilles"
      #
      # @faker.version 1.7.0
      def hero
        fetch('ancient.hero')
      end
    end
  end
end
