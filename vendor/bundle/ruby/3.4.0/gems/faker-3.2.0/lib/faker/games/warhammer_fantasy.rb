# frozen_string_literal: true

module Faker
  class Games
    class WarhammerFantasy < Base
      class << self
        ##
        # Produces the name of a hero from the Warhammer Fantasy setting.
        #
        # @return [String]
        #
        # @example
        #   Faker::Games::WarhammerFantasy.hero #=> "Sigmar Heldenhammer"
        #
        # @faker.version 2.13.0
        def hero
          fetch('games.warhammer_fantasy.heros')
        end

        ##
        # Produces a quote from the Warhammer Fantasy setting.
        #
        # @return [String]
        #
        # @example
        #   Faker::Games::WarhammerFantasy.quote #=> "The softest part of a castle is the belly of the man inside."
        #
        # @faker.version 2.13.0
        def quote
          fetch('games.warhammer_fantasy.quotes')
        end

        ##
        # Produces a location from the Warhammer Fantasy setting.
        #
        # @return [String]
        #
        # @example
        #   Faker::Games::WarhammerFantasy.location #=> "Lustria"
        #
        # @faker.version 2.13.0
        def location
          fetch('games.warhammer_fantasy.locations')
        end

        ##
        # Produces a faction from the Warhammer Fantasy setting.
        #
        # @return [String]
        #
        # @example
        #   Faker::Games::WarhammerFantasy.faction #=> "Bretonnia"
        #
        # @faker.version 2.13.0
        def faction
          fetch('games.warhammer_fantasy.factions')
        end

        ##
        # Produces a creature from the Warhammer Fantasy setting.
        #
        # @return [String]
        #
        # @example
        #   Faker::Games::WarhammerFantasy.creature #=> "Hydra"
        #
        # @faker.version 2.13.0
        def creature
          fetch('games.warhammer_fantasy.creatures')
        end
      end
    end
  end
end
