# frozen_string_literal: true

module Faker
  class JapaneseMedia
    class DragonBall < Base
      class << self
        ##
        # Produces the name of a character from Dragon Ball.
        #
        # @return [String]
        #
        # @example
        #   Faker::Games::DragonBall.character #=> "Goku"
        #
        # @faker.version 1.8.0
        def character
          fetch('dragon_ball.characters')
        end

        ##
        # Produces the name of a race from Dragon Ball.
        #
        # @return [String]
        #
        # @example
        #   Faker::Games::DragonBall.race #=> "Saiyan"
        #
        # @faker.version next
        def race
          fetch('dragon_ball.races')
        end

        ##
        # Produces the name of a planet from Dragon Ball.
        #
        # @return [String]
        #
        # @example
        #   Faker::Games::DragonBall.planet #=> "Namek"
        #
        # @faker.version next
        def planet
          fetch('dragon_ball.planets')
        end
      end
    end
  end
end
