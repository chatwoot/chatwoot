# frozen_string_literal: true

module Faker
  class TvShows
    class GameOfThrones < Base
      flexible :game_of_thrones

      class << self
        ##
        # Produces a character from Game of Thrones.
        #
        # @return [String]
        #
        # @example
        #   Faker::TvShows::GameOfThrones.character #=> "Tyrion Lannister"
        #
        # @faker.version 1.6.6
        def character
          fetch('game_of_thrones.characters')
        end

        ##
        # Produces a house from Game of Thrones.
        #
        # @return [String]
        #
        # @example
        #   Faker::TvShows::GameOfThrones.house #=> "Stark"
        #
        # @faker.version 1.6.6
        def house
          fetch('game_of_thrones.houses')
        end

        ##
        # Produces a city from Game of Thrones.
        #
        # @return [String]
        #
        # @example
        #   Faker::TvShows::GameOfThrones.city #=> "Lannisport"
        #
        # @faker.version 1.6.6
        def city
          fetch('game_of_thrones.cities')
        end

        ##
        # Produces a quote from Game of Thrones.
        #
        # @return [String]
        #
        # @example
        #   Faker::TvShows::GameOfThrones.quote
        #     #=> "Never forget who you are. The rest of the world won't. Wear it like an armor and it can never be used against you."
        #
        # @faker.version 1.6.6
        def quote
          fetch('game_of_thrones.quotes')
        end

        ##
        # Produces a dragon from Game of Thrones.
        #
        # @return [String]
        #
        # @example
        #   Faker::TvShows::GameOfThrones.dragon #=> "Drogon"
        #
        # @faker.version 1.6.6
        def dragon
          fetch('game_of_thrones.dragons')
        end
      end
    end
  end
end
