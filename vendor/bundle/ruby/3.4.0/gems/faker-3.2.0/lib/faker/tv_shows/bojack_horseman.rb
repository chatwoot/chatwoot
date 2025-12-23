# frozen_string_literal: true

module Faker
  class TvShows
    class BojackHorseman < Base
      flexible :bojack_horseman

      class << self
        ##
        # Produces a character from BoJack Horseman.
        #
        # @return [String]
        #
        # @example
        #   Faker::TvShows::BojackHorseman.character #=> "BoJack Horseman"
        #
        # @faker.version 1.9.0
        def character
          fetch('bojack_horseman.characters')
        end

        ##
        # Produces a tongue twister from BoJack Horseman.
        #
        # @return [String]
        #
        # @example
        #   Faker::TvShows::BojackHorseman.tongue_twister #=> "Did you steal a meal from Neal McBeal the Navy Seal?"
        #
        # @faker.version 1.9.0
        def tongue_twister
          fetch('bojack_horseman.tongue_twisters')
        end

        ##
        # Produces a quote from BoJack Horseman.
        #
        # @return [String]
        #
        # @example
        #   Faker::TvShows::BojackHorseman.quote
        #     #=> "Not understanding that you're a horrible person doesn't make you less of a horrible person."
        #
        # @faker.version 1.9.0
        def quote
          fetch('bojack_horseman.quotes')
        end
      end
    end
  end
end
