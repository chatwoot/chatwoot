# frozen_string_literal: true

module Faker
  class JapaneseMedia
    class StudioGhibli < Base
      class << self
        ##
        # Produces a character from the Studio Ghibli.
        #
        # @return [String]
        #
        # @example
        #   Faker::JapaneseMedia::StudioGhibli.character #=> "Chihiro"
        #
        # @faker.version next
        def character
          fetch('studio_ghibli.characters')
        end

        ##
        # Produces a quote from Studio Ghibli's movies.
        #
        # @return [String]
        #
        # @example
        #   Faker::JapaneseMedia::StudioGhibli.quote #=> "One thing you can always count on is that hearts change."
        #
        # @faker.version next
        def quote
          fetch('studio_ghibli.quotes')
        end

        ##
        # Produces a movie from Studio Ghibli.
        #
        # @return [String]
        #
        # @example
        #   Faker::JapaneseMedia::StudioGhibli.movie #=> "Kiki's Delivery Service"
        #
        # @faker.version next
        def movie
          fetch('studio_ghibli.movies')
        end
      end
    end
  end
end
