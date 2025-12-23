# frozen_string_literal: true

module Faker
  class Games
    class SonicTheHedgehog < Base
      class << self
        ##
        # Produces the name of a character from Sonic the Hedgehog.
        #
        # @return [String]
        #
        # @example
        #   Faker::Games::SonicTheHedgehog.character #=> "Sonic the Hedgehog"
        #
        # @faker.version 1.9.2
        def character
          fetch('games.sonic_the_hedgehog.character')
        end

        ##
        # Produces the name of a zone from Sonic the Hedgehog.
        #
        # @return [String]
        #
        # @example
        #   Faker::Games::SonicTheHedgehog.zone #=> "Green Hill Zone"
        #
        # @faker.version 1.9.2
        def zone
          fetch('games.sonic_the_hedgehog.zone')
        end

        ##
        # Produces the name of a game from the Sonic the Hedgehog series.
        #
        # @return [String]
        #
        # @example
        #   Faker::Games::SonicTheHedgehog.game #=> "Waku Waku Sonic Patrol Car"
        #
        # @faker.version 1.9.2
        def game
          fetch('games.sonic_the_hedgehog.game')
        end
      end
    end
  end
end
