# frozen_string_literal: true

module Faker
  class TvShows
    class Stargate < Base
      flexible :stargate

      class << self
        ##
        # Produces a character from Stargate.
        #
        # @return [String]
        #
        # @example
        #   Faker::TvShows::Stargate.character #=> "Jack O'Neill"
        #
        # @faker.version 1.8.5
        def character
          fetch('stargate.characters')
        end

        ##
        # Produces a planet from Stargate.
        #
        # @return [String]
        #
        # @example
        #   Faker::TvShows::Stargate.planet #=> "Abydos"
        #
        # @faker.version 1.8.5
        def planet
          fetch('stargate.planets')
        end

        ##
        # Produces a quote from Stargate.
        #
        # @return [String]
        #
        # @example
        #   Faker::TvShows::Stargate.quote
        #     #=> "General, request permission to beat the crap out of this man."
        #
        # @faker.version 1.8.5
        def quote
          fetch('stargate.quotes')
        end
      end
    end
  end
end
