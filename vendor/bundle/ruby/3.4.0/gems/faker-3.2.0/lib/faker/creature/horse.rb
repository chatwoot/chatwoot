# frozen_string_literal: true

module Faker
  class Creature
    class Horse < Base
      flexible :horse

      class << self
        ##
        # Produces a random name for a horse
        #
        # @return [String]
        #
        # @example
        #   Faker::Creature::Horse.name #=> "Noir"
        #
        # @faker.version 1.9.2
        def name
          fetch('creature.horse.name')
        end

        ##
        # Produces a random horse breed
        #
        # @return [String]
        #
        # @example
        #   Faker::Creature::Horse.breed #=> "Spanish Barb see Barb Horse"
        #
        # @faker.version 1.9.2
        def breed
          fetch('creature.horse.breed')
        end
      end
    end
  end
end
