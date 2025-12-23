# frozen_string_literal: true

module Faker
  class Games
    class ClashOfClans < Base
      class << self
        ##
        # Produces the name of a troop from Clash of Clans.
        #
        # @return [String]
        #
        # @example
        #   Faker::Games::ClashOfClans.troop #=> "Barbarian"
        #
        # @faker.version next
        def troop
          fetch('games.clash_of_clans.troops')
        end

        ##
        # Produces the name of a rank from Clash Of Clans.
        #
        # @return [String]
        #
        # @example
        #   Faker::Games::ClashOfClans.rank #=> "Legend"
        #
        # @faker.version next
        def rank
          fetch('games.clash_of_clans.ranks')
        end

        ##
        # Produces the name of a defensive building from Clash Of Clans.
        #
        # @return [String]
        #
        # @example
        #   Faker::Games::ClashOfClans.defensive_building #=> "Cannon"
        #
        # @faker.version next
        def defensive_building
          fetch('games.clash_of_clans.defensive_buildings')
        end
      end
    end
  end
end
