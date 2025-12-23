# frozen_string_literal: true

module Faker
  class TvShows
    class VentureBros < Base
      flexible :venture_bros

      class << self
        ##
        # Produces a character from The Venture Bros.
        #
        # @return [String]
        #
        # @example
        #   Faker::TvShows::VentureBros.character #=> "Scaramantula"
        #
        # @faker.version 1.8.3
        def character
          fetch('venture_bros.character')
        end

        ##
        # Produces an organization from The Venture Bros.
        #
        # @return [String]
        #
        # @example
        #   Faker::TvShows::VentureBros.organization
        #     #=> "Guild of Calamitous Intent"
        #
        # @faker.version 1.8.3
        def organization
          fetch('venture_bros.organization')
        end

        ##
        # Produces a vehicle from The Venture Bros.
        #
        # @return [String]
        #
        # @example
        #   Faker::TvShows::VentureBros.vehicle #=> "Monarchmobile"
        #
        # @faker.version 1.8.3
        def vehicle
          fetch('venture_bros.vehicle')
        end

        ##
        # Produces a quote from The Venture Bros.
        #
        # @return [String]
        #
        # @example
        #   Faker::TvShows::VentureBros.quote
        #     #=> "Revenge, like gazpacho soup, is best served cold, precise, and merciless."
        #
        # @faker.version 1.8.3
        def quote
          fetch('venture_bros.quote')
        end
      end
    end
  end
end
