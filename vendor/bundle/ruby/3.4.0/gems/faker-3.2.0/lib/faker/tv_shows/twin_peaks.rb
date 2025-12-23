# frozen_string_literal: true

module Faker
  class TvShows
    class TwinPeaks < Base
      flexible :twin_peaks

      class << self
        ##
        # Produces a character from Twin Peaks.
        #
        # @return [String]
        #
        # @example
        #   Faker::TvShows::TwinPeaks.character #=> "Dale Cooper"
        #
        # @faker.version 1.7.0
        def character
          fetch('twin_peaks.characters')
        end

        ##
        # Produces a location from Twin Peaks.
        #
        # @return [String]
        #
        # @example
        #   Faker::TvShows::TwinPeaks.location #=> "Black Lodge"
        #
        # @faker.version 1.7.0
        def location
          fetch('twin_peaks.locations')
        end

        ##
        # Produces a quote from Twin Peaks.
        #
        # @return [String]
        #
        # @example
        #   Faker::TvShows::TwinPeaks.quote
        #     #=> "The owls are not what they seem."
        #
        # @faker.version 1.7.0
        def quote
          fetch('twin_peaks.quotes')
        end
      end
    end
  end
end
