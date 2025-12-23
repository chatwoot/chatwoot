# frozen_string_literal: true

module Faker
  class Games
    class HalfLife < Base
      class << self
        ##
        # Produces the name of a character from the Half-Life games.
        #
        # @return [String]
        #
        # @example
        #   Faker::Games::HalfLife.character #=> "Gordon Freeman"
        #
        # @faker.version 1.9.2
        def character
          fetch('games.half_life.character')
        end

        ##
        # Produces the name of an enemy from the Half-Life games.
        #
        # @return [String]
        #
        # @example
        #   Faker::Games::HalfLife.enemy #=> "Headcrab"
        #
        # @faker.version 1.9.2
        def enemy
          fetch('games.half_life.enemy')
        end

        ##
        # Produces the name of a location from the Half-Life games.
        #
        # @return [String]
        #
        # @example
        #   Faker::Games::HalfLife.location #=> "Black Mesa Research Facility"
        #
        # @faker.version 1.9.2
        def location
          fetch('games.half_life.location')
        end
      end
    end
  end
end
