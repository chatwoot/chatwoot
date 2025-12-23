# frozen_string_literal: true

module Faker
  class Cosmere < Base
    flexible :cosmere
    class << self
      ##
      # Produces a random aon.
      #
      # @return [String]
      #
      # @example
      #   Faker::Cosmere.aon #=> "Rao"
      #
      # @faker.version 1.9.2
      def aon
        sample(aons)
      end

      ##
      # Produces a random shard world.
      #
      # @return [String]
      #
      # @example
      #   Faker::Cosmere.shard_world #=> "Yolen"
      #
      # @faker.version 1.9.2
      def shard_world
        sample(shard_worlds)
      end

      ##
      # Produces a random shard.
      #
      # @return [String]
      #
      # @example
      #   Faker::Cosmere.shard #=> "Ambition"
      #
      # @faker.version 1.9.2
      def shard
        sample(shards)
      end

      ##
      # Produces a random surge.
      #
      # @return [String]
      #
      # @example
      #   Faker::Cosmere.surge #=> "Progression"
      #
      # @faker.version 1.9.2
      def surge
        sample(surges)
      end

      ##
      # Produces a random knight radiant.
      #
      # @return [String]
      #
      # @example
      #   Faker::Cosmere.knight_radiant #=> "Truthwatcher"
      #
      # @faker.version 1.9.2
      def knight_radiant
        sample(knights_radiant)
      end

      ##
      # Produces a random metal.
      #
      # @return [String]
      #
      # @example
      #   Faker::Cosmere.metal #=> "Brass"
      #
      # @faker.version 1.9.2
      def metal
        sample(metals)
      end

      ##
      # Produces a random allomancer.
      #
      # @return [String]
      #
      # @example
      #   Faker::Cosmere.allomancer #=> "Coinshot"
      #
      # @faker.version 1.9.2
      def allomancer
        sample(allomancers)
      end

      ##
      # Produces a random feruchemist.
      #
      # @return [String]
      #
      # @example
      #   Faker::Cosmere.feruchemist #=> "Archivist"
      #
      # @faker.version 1.9.2
      def feruchemist
        sample(feruchemists)
      end

      ##
      # Produces a random herald.
      #
      # @return [String]
      #
      # @example
      #   Faker::Cosmere.herald #=> "Ishar"
      #
      # @faker.version 1.9.2
      def herald
        sample(heralds)
      end

      ##
      # Produces a random spren.
      #
      # @return [String]
      #
      # @example
      #   Faker::Cosmere.spren #=> "Flamespren"
      #
      # @faker.version 1.9.2
      def spren
        sample(sprens)
      end
    end
  end
end
