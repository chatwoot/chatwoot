# frozen_string_literal: true

module Faker
  class Games
    class Fallout < Base
      class << self
        ##
        # Produces the name of a character from the Fallout games.
        #
        # @return [String]
        #
        # @example
        #   Faker::Games::Fallout.character #=> "Liberty Prime"
        #
        # @faker.version 1.9.2
        def character
          fetch('games.fallout.characters')
        end

        ##
        # Produces the name of a faction from the Fallout games.
        #
        # @return [String]
        #
        # @example
        #   Faker::Games::Fallout.faction #=> "Brotherhood of Steel"
        #
        # @faker.version 1.9.2
        def faction
          fetch('games.fallout.factions')
        end

        ##
        # Produces the name of a location from the Fallout games.
        #
        # @return [String]
        #
        # @example
        #   Faker::Games::Fallout.location #=> "New Vegas"
        #
        # @faker.version 1.9.2
        def location
          fetch('games.fallout.locations')
        end

        ##
        # Produces a quote from the Fallout games.
        #
        # @return [String]
        #
        # @example
        #   Faker::Games::Fallout.quote
        #     #=> "Democracy is non-negotiable"
        #
        # @faker.version 1.9.2
        def quote
          fetch('games.fallout.quotes')
        end
      end
    end
  end
end
