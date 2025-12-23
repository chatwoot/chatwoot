# frozen_string_literal: true

module Faker
  class TvShows
    class BrooklynNineNine < Base
      flexible :brooklyn_nine_nine

      class << self
        ##
        # Produces a character from Brooklyn Nine Nine.
        #
        # @return [String]
        #
        # @example
        #   Faker::TvShows::BrooklynNineNine.character #=> "Jake Peralta"
        #
        # @faker.version next
        def character
          fetch('brooklyn_nine_nine.characters')
        end

        ##
        # Produces a quote from Brooklyn Nine Nine.
        #
        # @return [String]
        #
        # @example
        #   Faker::TvShows::BrooklynNineNine.quote
        #     #=> "Cool, cool, cool, cool, cool. No doubt, no doubt, no doubt."
        #
        # @faker.version next
        def quote
          fetch('brooklyn_nine_nine.quotes')
        end
      end
    end
  end
end
