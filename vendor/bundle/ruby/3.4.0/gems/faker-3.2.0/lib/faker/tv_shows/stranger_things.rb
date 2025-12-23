# frozen_string_literal: true

module Faker
  class TvShows
    class StrangerThings < Base
      flexible :stranger_things

      class << self
        ##
        # Produces a character from Stranger Things.
        #
        # @return [String]
        #
        # @example
        #   Faker::TvShows::StrangerThings.character #=> "six"
        #
        # @faker.version 1.9.0
        def quote
          fetch('stranger_things.quote')
        end

        ##
        # Produces a quote from Stranger Things.
        #
        # @return [String]
        #
        # @example
        #   Faker::TvShows::StrangerThings.quote
        #     #=> "Friends don't lie."
        #
        # @faker.version 1.9.0
        def character
          fetch('stranger_things.character')
        end
      end
    end
  end
end
