# frozen_string_literal: true

module Faker
  class TvShows
    class Seinfeld < Base
      flexible :seinfeld

      class << self
        ##
        # Produces a business from Seinfeld.
        #
        # @return [String]
        #
        # @example
        #   Faker::TvShows::Seinfeld.business #=> "Kruger Industrial Smoothing"
        #
        # @faker.version 1.9.2
        def business
          fetch('seinfeld.business')
        end

        ##
        # Produces a character from Seinfeld.
        #
        # @return [String]
        #
        # @example
        #   Faker::TvShows::Seinfeld.character #=> "George Costanza"
        #
        # @faker.version 1.8.3
        def character
          fetch('seinfeld.character')
        end

        ##
        # Produces a quote from Seinfeld.
        #
        # @return [String]
        #
        # @example
        #   Faker::TvShows::Seinfeld.quote
        #     #=> "I'm not a lesbian. I hate men, but I'm not a lesbian."
        #
        # @faker.version 1.8.3
        def quote
          fetch('seinfeld.quote')
        end
      end
    end
  end
end
