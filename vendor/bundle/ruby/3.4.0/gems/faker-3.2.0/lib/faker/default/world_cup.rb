# frozen_string_literal: true

module Faker
  class WorldCup < Base
    class << self
      ##
      # Produces a national team name.
      #
      # @return [String]
      #
      # @example
      #   Faker::WorldCup.team #=> "Iran"
      #
      # @faker.version 1.9.0
      def team
        fetch('world_cup.teams')
      end

      ##
      # Produces a city name hosting the World Cup match.
      #
      # @return [String]
      #
      # @example
      #   Faker::WorldCup.city #=> "Moscow"
      #
      # @faker.version 2.13.0
      def city
        fetch('world_cup.cities')
      end

      ##
      # Produces the name of a stadium that has hosted a World Cup match.
      #
      # @return [String]
      #
      # @example
      #   Faker::WorldCup.stadium #=> "Rostov Arena"
      #
      # @faker.version 2.13.0
      def stadium
        fetch('world_cup.stadiums')
      end

      ##
      # Produces a random national team name from a group.
      #
      # @return [String]
      #
      # @example
      #   Faker::WorldCup.group(group: 'group_B') #=> "Spain"
      # @example
      #   Faker::WorldCup.group #=> "Russia"
      #
      # @faker.version 2.13.0
      def group(group: 'group_A')
        fetch("world_cup.groups.#{group}")
      end

      ##
      # Produces a random name from national team roster.
      #
      # @return [String]
      #
      # @example
      #   Faker::WorldCup.roster #=> "Hector Cuper"
      #
      # @example
      #   Faker::WorldCup.roster(country: 'Spain', type: 'forwards') #=> "Diego Costa"
      #
      # @faker.version 2.13.0
      def roster(country: 'Egypt', type: 'coach')
        fetch("world_cup.rosters.#{country}.#{type}")
      end
    end
  end
end
