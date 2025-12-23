# frozen_string_literal: true

module Faker
  class JapaneseMedia
    class CowboyBebop < Base
      class << self
        ##
        # Produces a character from Cowboy Bebop.
        #
        # @return [String]
        #
        # @example
        #   Faker::JapaneseMedia::CowboyBebop.character #=> "Spike Spiegel"
        #
        # @faker.version next
        def character
          fetch('cowboy_bebop.character')
        end

        ##
        # Produces an episode from Cowboy Bebop.
        #
        # @return [String]
        #
        # @example
        #   Faker::JapaneseMedia::CowboyBebop.episode #=> "Honky Tonk Women"
        #
        # @faker.version next
        def episode
          fetch('cowboy_bebop.episode')
        end

        ##
        # Produces a song title from Cowboy Bebop.
        #
        # @return [String]
        #
        # @example
        #   Faker::JapaneseMedia::CowboyBebop.songs #=> "Live in Baghdad"
        #
        # @faker.version next
        def song
          fetch('cowboy_bebop.song')
        end

        ##
        # Produces a quote from Cowboy Bebop.
        #
        # @return [String]
        #
        # @example
        #   Faker::JapaneseMedia::CowboyBebop.quote #=> "Bang!!!"
        #
        # @faker.version next
        def quote
          fetch('cowboy_bebop.quote')
        end
      end
    end
  end
end
