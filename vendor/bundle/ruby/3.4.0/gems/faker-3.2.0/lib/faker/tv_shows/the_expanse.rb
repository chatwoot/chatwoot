# frozen_string_literal: true

module Faker
  class TvShows
    class TheExpanse < Base
      flexible :the_expanse

      class << self
        ##
        # Produces a character from The Expanse.
        #
        # @return [String]
        #
        # @example
        #   Faker::TvShows::TheExpanse.character #=> "Jim Holden"
        #
        # @faker.version 1.9.2
        def character
          fetch('the_expanse.characters')
        end

        ##
        # Produces a quote from The Expanse.
        #
        # @return [String]
        #
        # @example
        #   Faker::TvShows::TheExpanse.quote #=> "I am that guy."
        #
        # @faker.version 1.9.2
        def quote
          fetch('the_expanse.quotes')
        end

        ##
        # Produces a location from The Expanse.
        #
        # @return [String]
        #
        # @example
        #   Faker::TvShows::TheExpanse.location #=> "Ganymede"
        #
        # @faker.version 1.9.2
        def location
          fetch('the_expanse.locations')
        end

        ##
        # Produces a ship from The Expanse.
        #
        # @return [String]
        #
        # @example
        #   Faker::TvShows::TheExpanse.ship #=> "Nauvoo"
        #
        # @faker.version 1.9.2
        def ship
          fetch('the_expanse.ships')
        end
      end
    end
  end
end
