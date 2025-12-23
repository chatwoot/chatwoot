# frozen_string_literal: true

module Faker
  class Sports
    class Volleyball < Base
      class << self
        ##
        # Produces the name of a volleyball team.
        #
        # @return [String]
        #
        # @example
        #   Faker::Sports::Volleyball.team #=> "Leo Shoes Modena"
        #
        # @faker.version next
        def team
          fetch('volleyball.team')
        end

        ##
        # Produces the name of a volleyball player.
        #
        # @return [String]
        #
        # @example
        #   Faker::Sports::Volleyball.player #=> "Saeid Marouf"
        #
        # @faker.version next
        def player
          fetch('volleyball.player')
        end

        ##
        # Produces the name of a volleyball coach.
        #
        # @return [String]
        #
        # @example
        #   Faker::Sports::Volleyball.coach #=> "Russ Rose"
        #
        # @faker.version next
        def coach
          fetch('volleyball.coach')
        end

        ##
        # Produces a position in volleyball.
        #
        # @return [String]
        #
        # @example
        #   Faker::Sports::Volleyball.position #=> "Middle blocker"
        #
        # @faker.version next
        def position
          fetch('volleyball.position')
        end

        ##
        # Produces a formation in volleyball.
        #
        # @return [String]
        #
        # @example
        #   Faker::Sports::Volleyball.formation #=> "4-2"
        #
        # @faker.version next
        def formation
          fetch('volleyball.formation')
        end
      end
    end
  end
end
