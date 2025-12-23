# frozen_string_literal: true

module Faker
  class TvShows
    class RickAndMorty < Base
      flexible :rick_and_morty

      class << self
        ##
        # Produces a character from Rick and Morty.
        #
        # @return [String]
        #
        # @example
        #   Faker::TvShows::RickAndMorty.character #=> "Rick Sanchez"
        #
        # @faker.version 1.8.0
        def character
          fetch('rick_and_morty.characters')
        end

        ##
        # Produces a location from Rick and Morty.
        #
        # @return [String]
        #
        # @example
        #   Faker::TvShows::RickAndMorty.location #=> "Dimension C-132"
        #
        # @faker.version 1.8.0
        def location
          fetch('rick_and_morty.locations')
        end

        ##
        # Produces a quote from Rick and Morty.
        #
        # @return [String]
        #
        # @example
        #   Faker::TvShows::RickAndMorty.quote
        #     #=> "Ohh yea, you gotta get schwifty."
        #
        # @faker.version 1.8.0
        def quote
          fetch('rick_and_morty.quotes')
        end
      end
    end
  end
end
