# frozen_string_literal: true

module Faker
  class Games
    class LeagueOfLegends < Base
      class << self
        ##
        # Produces the name of a champion from League of Legends.
        #
        # @return [String]
        #
        # @example
        #   Faker::Games::LeagueOfLegends.champion #=> "Jarvan IV"
        #
        # @faker.version 1.8.0
        def champion
          fetch('games.league_of_legends.champion')
        end

        ##
        # Produces a location from League of Legends.
        #
        # @return [String]
        #
        # @example
        #   Faker::Games::LeagueOfLegends.location #=> "Demacia"
        #
        # @faker.version 1.8.0
        def location
          fetch('games.league_of_legends.location')
        end

        ##
        # Produces a quote from League of Legends.
        #
        # @return [String]
        #
        # @example
        #   Faker::Games::LeagueOfLegends.quote #=> "Purge the unjust."
        #
        # @faker.version 1.8.0
        def quote
          fetch('games.league_of_legends.quote')
        end

        ##
        # Produces a summoner spell from League of Legends.
        #
        # @return [String]
        #
        # @example
        #   Faker::Games::LeagueOfLegends.summoner_spell #=> "Flash"
        #
        # @faker.version 1.8.0
        def summoner_spell
          fetch('games.league_of_legends.summoner_spell')
        end

        ##
        # Produces a mastery from League of Legends.
        #
        # @return [String]
        #
        # @example
        #   Faker::Games::LeagueOfLegends.masteries #=> "Double Edged Sword"
        #
        # @faker.version 1.8.0
        def masteries
          fetch('games.league_of_legends.masteries')
        end

        ##
        # Produces a rank from League of Legends.
        #
        # @return [String]
        #
        # @example
        #   Faker::Games::LeagueOfLegends.rank #=> "Bronze V"
        #
        # @faker.version 1.8.0
        def rank
          fetch('games.league_of_legends.rank')
        end
      end
    end
  end
end
