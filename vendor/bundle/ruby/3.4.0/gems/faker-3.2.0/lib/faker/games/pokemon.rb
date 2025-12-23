# frozen_string_literal: true

module Faker
  class Games
    class Pokemon < Base
      class << self
        ##
        # Produces the name of a Pokemon.
        #
        # @return [String]
        #
        # @example
        #   Faker::Games::Pokemon.name #=> "Pikachu"
        #
        # @faker.version 1.7.0
        def name
          fetch('games.pokemon.names')
        end

        ##
        # Produces a location from Pokemon.
        #
        # @return [String]
        #
        # @example
        #   Faker::Games::Pokemon.location #=> "Pallet Town"
        #
        # @faker.version 1.7.0
        def location
          fetch('games.pokemon.locations')
        end

        ##
        # Produces a move from Pokemon.
        #
        # @return [String]
        #
        # @example
        #   Faker::Games::Pokemon.move #=> "Thunder Shock"
        #
        # @faker.version 1.7.0
        def move
          fetch('games.pokemon.moves')
        end
      end
    end
  end
end
