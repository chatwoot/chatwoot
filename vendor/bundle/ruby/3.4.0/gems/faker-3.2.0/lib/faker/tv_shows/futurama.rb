# frozen_string_literal: true

module Faker
  class TvShows
    class Futurama < Base
      flexible :futurama

      class << self
        ##
        # Produces a character from Futurama.
        #
        # @return [String]
        #
        # @example
        #   Faker::TvShows::Futurama.character #=> "Amy Wong"
        #
        # @faker.version 2.13.0
        def character
          fetch('futurama.characters')
        end

        ##
        # Produces a location from Futurama.
        #
        # @return [String]
        #
        # @example
        #   Faker::TvShows::Futurama.location #=> "Wormulon"
        #
        # @faker.version 2.13.0
        def location
          fetch('futurama.locations')
        end

        ##
        # Produces a quote from Futurama.
        #
        # @return [String]
        #
        # @example
        #   Faker::TvShows::Futurama.quote
        #     #=> "Ugh, it's like a party in my mouth & everyone's throwing up."
        #
        # @faker.version 2.13.0
        def quote
          fetch('futurama.quotes')
        end

        ##
        # Produces a catchphrase from Hermes Conrad.
        #
        # @return [String]
        #
        # @example
        #   Faker::TvShows::Futurama.hermes_catchphrase
        #     #=> "Great foo of bar!"
        #
        # @faker.version 2.13.0
        def hermes_catchphrase
          fetch('futurama.hermes_catchphrases')
        end
      end
    end
  end
end
