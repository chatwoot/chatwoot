# frozen_string_literal: true

module Faker
  class TvShows
    class DumbAndDumber < Base
      flexible :dumb_and_dumber

      class << self
        ##
        # Produces an actor from Dumb and Dumber.
        #
        # @return [String]
        #
        # @example
        #   Faker::TvShows::DumbAndDumber.actor #=> "Jim Carrey"
        #
        # @faker.version 1.8.5
        def actor
          fetch('dumb_and_dumber.actors')
        end

        ##
        # Produces a character from Dumb and Dumber.
        #
        # @return [String]
        #
        # @example
        #   Faker::TvShows::DumbAndDumber.character #=> "Harry Dunne"
        #
        # @faker.version 1.8.5
        def character
          fetch('dumb_and_dumber.characters')
        end

        ##
        # Produces a quote from Dumb and Dumber.
        #
        # @return [String]
        #
        # @example
        #   Faker::TvShows::DumbAndDumber.quote
        #     #=> "Why you going to the airport? Flying somewhere?"
        #
        # @faker.version 1.8.5
        def quote
          fetch('dumb_and_dumber.quotes')
        end
      end
    end
  end
end
