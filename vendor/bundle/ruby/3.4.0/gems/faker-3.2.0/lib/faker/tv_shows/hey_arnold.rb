# frozen_string_literal: true

module Faker
  class TvShows
    class HeyArnold < Base
      flexible :hey_arnold

      class << self
        ##
        # Produces a character from Hey Arnold!
        #
        # @return [String]
        #
        # @example
        #   Faker::TvShows::HeyArnold.character #=> "Arnold"
        #
        # @faker.version 1.8.0
        def character
          fetch('hey_arnold.characters')
        end

        ##
        # Produces a location from Hey Arnold!
        #
        # @return [String]
        #
        # @example
        #   Faker::TvShows::HeyArnold.location #=> "Big Bob's Beeper Emporium"
        #
        # @faker.version 1.8.0
        def location
          fetch('hey_arnold.locations')
        end

        ##
        # Produces a quote from Hey Arnold!
        #
        # @return [String]
        #
        # @example
        #   Faker::TvShows::HeyArnold.quote #=> "Stoop Kid's afraid to leave his stoop!"
        #
        # @faker.version 1.8.0
        def quote
          fetch('hey_arnold.quotes')
        end
      end
    end
  end
end
