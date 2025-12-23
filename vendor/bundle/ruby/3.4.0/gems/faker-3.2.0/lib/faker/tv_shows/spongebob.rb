# frozen_string_literal: true

module Faker
  class TvShows
    class Spongebob < Base
      flexible :spongebob

      class << self
        ##
        # Produces a character from Spongebob.
        #
        # @return [String]
        #
        # @example
        #   Faker::TvShows::Spongebob.character #=> "Patrick"
        #
        # @faker.version next
        def character
          fetch('spongebob.characters')
        end

        ##
        # Produces a quote from Spongebob.
        #
        # @return [String]
        #
        # @example
        #   Faker::TvShows::Spongebob.quote #=> "I'm ready! I'm ready!"
        #
        # @faker.version next
        def quote
          fetch('spongebob.quotes')
        end

        ##
        # Produces an episode from Spongebob.
        #
        # @return [String]
        #
        # @example
        #   Faker::TvShows::Spongebob.episode #=> "Reef Blower"
        #
        # @faker.version next
        def episode
          fetch('spongebob.episodes')
        end
      end
    end
  end
end
