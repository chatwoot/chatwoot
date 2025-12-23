# frozen_string_literal: true

module Faker
  class TvShows
    class ParksAndRec < Base
      flexible :parks_and_rec

      class << self
        ##
        # Produces a character from Parks and Recreation.
        #
        # @return [String]
        #
        # @example
        #   Faker::TvShows::ParksAndRec.character #=> "Leslie Knope"
        #
        # @faker.version 1.9.0
        def character
          fetch('parks_and_rec.characters')
        end

        ##
        # Produces a city from Parks and Recreation.
        #
        # @return [String]
        #
        # @example
        #   Faker::TvShows::ParksAndRec.city #=> "Pawnee"
        #
        # @faker.version 1.9.0
        def city
          fetch('parks_and_rec.cities')
        end
      end
    end
  end
end
