# frozen_string_literal: true

module Faker
  class Sports
    class Football < Base
      class << self
        ##
        # Produces the name of a football team.
        #
        # @return [String]
        #
        # @example
        #   Faker::Sports::Football.team #=> "Manchester United"
        #
        # @faker.version 1.9.0
        def team
          fetch('football.teams')
        end

        ##
        # Produces the name of a football player.
        #
        # @return [String]
        #
        # @example
        #   Faker::Sports::Football.player #=> "Lionel Messi"
        #
        # @faker.version 1.9.0
        def player
          fetch('football.players')
        end

        ##
        # Produces the name of a football coach.
        #
        # @return [String]
        #
        # @example
        #   Faker::Sports::Football.coach #=> "Jose Mourinho"
        #
        # @faker.version 1.9.0
        def coach
          fetch('football.coaches')
        end

        ##
        # Produces a football competition.
        #
        # @return [String]
        #
        # @example
        #   Faker::Sports::Football.competition #=> "FIFA World Cup"
        #
        # @faker.version 1.9.0
        def competition
          fetch('football.competitions')
        end

        ##
        # Produces a position in football.
        #
        # @return [String]
        #
        # @example
        #   Faker::Sports::Football.position #=> "Defensive Midfielder"
        #
        # @faker.version 1.9.2
        def position
          fetch('football.positions')
        end
      end
    end
  end
end
