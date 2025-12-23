# frozen_string_literal: true

module Faker
  class TvShows
    class StarTrek < Base
      flexible :star_trek

      class << self
        ##
        # Produces a character from Star Trek.
        #
        # @return [String]
        #
        # @example
        #   Faker::TvShows::StarTrek.character #=> "Spock"
        #
        # @faker.version 1.8.0
        def character
          fetch('star_trek.character')
        end

        ##
        # Produces a location from Star Trek.
        #
        # @return [String]
        #
        # @example
        #   Faker::TvShows::StarTrek.location #=> "Cardassia"
        #
        # @faker.version 1.8.0
        def location
          fetch('star_trek.location')
        end

        ##
        # Produces a species from Star Trek.
        #
        # @return [String]
        #
        # @example
        #   Faker::TvShows::StarTrek.specie #=> "Ferengi"
        #
        # @faker.version 1.8.0
        def specie
          fetch('star_trek.specie')
        end

        ##
        # Produces a villain from Star Trek.
        #
        # @return [String]
        #
        # @example
        #   Faker::TvShows::StarTrek.villain #=> "Khan Noonien Singh"
        #
        # @faker.version 1.8.0
        def villain
          fetch('star_trek.villain')
        end
      end
    end
  end
end
