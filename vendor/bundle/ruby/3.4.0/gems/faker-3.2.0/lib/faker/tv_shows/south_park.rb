# frozen_string_literal: true

module Faker
  class TvShows
    class SouthPark < Base
      flexible :south_park

      class << self
        ##
        # Produces a character from South Park.
        #
        # @return [String]
        #
        # @example
        #   Faker::TvShows::SouthPark.character #=> "Mr. Garrison"
        #
        # @faker.version 1.9.2
        def character
          fetch('south_park.characters')
        end

        ##
        # Produces a quote from South Park.
        #
        # @return [String]
        #
        # @example
        #   Faker::TvShows::SouthPark.quote
        #     #=> "I'm just getting a little cancer Stan."
        #
        # @faker.version 1.9.2
        def quote
          fetch('south_park.quotes')
        end
      end
    end
  end
end
