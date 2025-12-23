# frozen_string_literal: true

module Faker
  class Games
    class SuperMario < Base
      class << self
        ##
        # Produces the name of a Super Mario character.
        #
        # @return [String]
        #
        # @example
        #   Faker::Games::SuperMario.character #=> "Luigi"
        #
        # @faker.version next
        def character
          fetch('games.super_mario.characters')
        end

        ##
        # Produces the name of a Super Mario game.
        #
        # @return [String]
        #
        # @example
        #   Faker::Games::SuperMario.game #=> "Super Mario Odyssey"
        #
        # @faker.version next
        def game
          fetch('games.super_mario.games')
        end

        ##
        # Produces the name of a Super Mario location.
        #
        # @return [String]
        #
        # @example
        #   Faker::Games::SuperMario.location #=> "Kong City"
        #
        # @faker.version next
        def location
          fetch('games.super_mario.locations')
        end
      end
    end
  end
end
