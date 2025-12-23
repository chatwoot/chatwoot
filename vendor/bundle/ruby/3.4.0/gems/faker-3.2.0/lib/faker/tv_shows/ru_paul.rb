# frozen_string_literal: true

module Faker
  class TvShows
    class RuPaul < Base
      flexible :rupaul

      class << self
        ##
        # Produces a quote from RuPaul's Drag Race.
        #
        # @return [String]
        #
        # @example
        #   Faker::TvShows::RuPaul.quote #=> "That's Funny, Tell Another One."
        #
        # @faker.version 1.8.0
        def quote
          fetch('rupaul.quotes')
        end

        ##
        # Produces a queen from RuPaul's Drag Race.
        #
        # @return [String]
        #
        # @example
        #   Faker::TvShows::RuPaul.queen #=> "Latrice Royale"
        #
        # @faker.version 1.8.0
        def queen
          fetch('rupaul.queens')
        end
      end
    end
  end
end
