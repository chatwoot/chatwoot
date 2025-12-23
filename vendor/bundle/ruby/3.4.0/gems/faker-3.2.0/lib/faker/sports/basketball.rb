# frozen_string_literal: true

module Faker
  class Sports
    class Basketball < Base
      class << self
        ##
        # Produces the name of a basketball team.
        #
        # @return [String]
        #
        # @example
        #   Faker::Sports::Basketball.team #=> "Golden State Warriors"
        #
        # @faker.version 1.9.4
        def team
          fetch('basketball.teams')
        end

        ##
        # Produces the name of a basketball player.
        #
        # @return [String]
        #
        # @example
        #   Faker::Sports::Basketball.player #=> "LeBron James"
        #
        # @faker.version 1.9.4
        def player
          fetch('basketball.players')
        end

        ##
        # Produces the name of a basketball coach.
        #
        # @return [String]
        #
        # @example
        #   Faker::Sports::Basketball.coach #=> "Gregg Popovich"
        #
        # @faker.version 1.9.4
        def coach
          fetch('basketball.coaches')
        end

        ##
        # Produces a position in basketball.
        #
        # @return [String]
        #
        # @example
        #   Faker::Sports::Basketball.position #=> "Point Guard"
        #
        # @faker.version 1.9.4
        def position
          fetch('basketball.positions')
        end
      end
    end
  end
end
