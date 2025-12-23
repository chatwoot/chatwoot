# frozen_string_literal: true

module Faker
  class TvShows
    class HowIMetYourMother < Base
      flexible :how_i_met_your_mother

      class << self
        ##
        # Produces a character from How I Met Your Mother.
        #
        # @return [String]
        #
        # @example
        #   Faker::TvShows::HowIMetYourMother.character #=> "Barney Stinson"
        #
        # @faker.version 1.8.0
        def character
          fetch('how_i_met_your_mother.character')
        end

        ##
        # Produces a catch phrase from How I Met Your Mother.
        #
        # @return [String]
        #
        # @example
        #   Faker::TvShows::HowIMetYourMother.catch_phrase #=> "Legendary"
        #
        # @faker.version 1.8.0
        def catch_phrase
          fetch('how_i_met_your_mother.catch_phrase')
        end

        ##
        # Produces a high five from How I Met Your Mother.
        #
        # @return [String]
        #
        # @example
        #   Faker::TvShows::HowIMetYourMother.high_five #=> "Relapse Five"
        #
        # @faker.version 1.8.0
        def high_five
          fetch('how_i_met_your_mother.high_five')
        end

        ##
        # Produces a quote from How I Met Your Mother.
        #
        # @return [String]
        #
        # @example
        #   Faker::TvShows::HowIMetYourMother.quote
        #     #=> "Whenever I'm sad, I stop being sad and be awesome instead."
        #
        # @faker.version 1.8.0
        def quote
          fetch('how_i_met_your_mother.quote')
        end
      end
    end
  end
end
