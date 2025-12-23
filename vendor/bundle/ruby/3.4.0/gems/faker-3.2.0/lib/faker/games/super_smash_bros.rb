# frozen_string_literal: true

module Faker
  class Games
    class SuperSmashBros < Base
      class << self
        ##
        # Produces the name of a fighter from the Smash Bros games.
        #
        # @return [String]
        #
        # @example
        #   Faker::Games::SuperSmashBros.fighter #=> "Mario"
        #
        # @faker.version 1.9.2
        def fighter
          fetch('games.super_smash_bros.fighter')
        end

        ##
        # Produces the name of a stage from the Smash Bros games.
        #
        # @return [String]
        #
        # @example
        #   Faker::Games::SuperSmashBros.stage #=> "Final Destination"
        #
        # @faker.version 1.9.2
        def stage
          fetch('games.super_smash_bros.stage')
        end
      end
    end
  end
end
