# frozen_string_literal: true

module Faker
  class Games
    class Dota < Base
      class << self
        ##
        # Produces the name of a building from Dota.
        #
        # @return [String]
        #
        # @example
        #   Faker::Games::Dota.building #=> "Tower"
        #
        # @faker.version 1.9.0
        def building
          fetch('games.dota.building')
        end

        ##
        # Produces the name of a hero from Dota.
        #
        # @return [String]
        #
        # @example
        #   Faker::Games::Dota.hero #=> "Abaddon"
        #
        # @faker.version 1.9.0
        def hero
          fetch('games.dota.hero')
        end

        ##
        # Produces the name of an item from Dota.
        #
        # @return [String]
        #
        # @example
        #   Faker::Games::Dota.item #=> "Armlet of Mordiggian"
        #
        # @faker.version 1.9.0
        def item
          fetch('games.dota.item')
        end

        ##
        # Produces the name of a professional Dota team.
        #
        # @return [String]
        #
        # @example
        #   Faker::Games::Dota.team #=> "Evil Geniuses"
        #
        # @faker.version 1.9.0
        def team
          fetch('games.dota.team')
        end

        ##
        # Produces the name of a professional Dota player.
        #
        # @return [String]
        #
        # @example
        #   Faker::Games::Dota.player #=> "Dendi"
        #
        # @faker.version 1.9.0
        def player
          fetch('games.dota.player')
        end

        ##
        # Produces the name of a hero from Dota.
        #
        # @param hero [String] The name of a Dota hero.
        # @return [String]
        #
        # @example
        #   Faker::Games::Dota.quote #=> "You have called death upon yourself."
        #   Faker::Games::Dota.quote(hero: 'alchemist') #=> "Better living through alchemy!"
        #
        # @faker.version 1.9.0
        def quote(hero: 'abaddon')
          fetch("games.dota.#{hero}.quote")
        end
      end
    end
  end
end
