# frozen_string_literal: true

module Faker
  class TvShows
    class Suits < Base
      flexible :suits

      class << self
        ##
        # Produces a character from Suits.
        #
        # @return [String]
        #
        # @example
        #   Faker::TvShows::Suits.character #=> "Harvey Specter"
        #
        # @faker.version 2.13.0
        def character
          fetch('suits.characters')
        end

        ##
        # Produces a quote from Suits.
        #
        # @return [String]
        #
        # @example
        #  Faker::TvShows::Suits.quote #=> "Don't play the odds, play the man."
        #
        # @faker.version 2.13.0
        def quote
          fetch('suits.quotes')
        end
      end
    end
  end
end
