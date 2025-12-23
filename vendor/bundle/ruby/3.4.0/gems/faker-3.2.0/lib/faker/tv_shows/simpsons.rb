# frozen_string_literal: true

module Faker
  class TvShows
    class Simpsons < Base
      flexible :simpsons

      class << self
        ##
        # Produces a character from The Simpsons.
        #
        # @return [String]
        #
        # @example
        #   Faker::TvShows::Simpsons.character #=> "Charles Montgomery Burns"
        #
        # @faker.version 1.8.0
        def character
          fetch('simpsons.characters')
        end

        ##
        # Produces a location from The Simpsons.
        #
        # @return [String]
        #
        # @example
        #   Faker::TvShows::Simpsons.location #=> "Moe's Tavern"
        #
        # @faker.version 1.8.0
        def location
          fetch('simpsons.locations')
        end

        ##
        # Produces a quote from The Simpsons.
        #
        # @return [String]
        #
        # @example
        #   Faker::TvShows::Simpsons.quote
        #     #=> "It takes two to lie: one to lie and one to listen."
        #
        # @faker.version 1.8.0
        def quote
          fetch('simpsons.quotes')
        end

        ##
        # Produces an episode title from The Simpsons.
        #
        # @return [String]
        #
        # @example
        #   Faker::TvShows::Simpsons.episode_title
        #     #=> "Two Cars in Every Garage and Three Eyes on Every Fish"
        #
        # @faker.version 2.13.0
        def episode_title
          fetch('simpsons.episode_titles')
        end
      end
    end
  end
end
