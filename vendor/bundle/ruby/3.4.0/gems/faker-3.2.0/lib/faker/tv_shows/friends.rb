# frozen_string_literal: true

module Faker
  class TvShows
    class Friends < Base
      flexible :friends

      class << self
        ##
        # Produces a character from Friends.
        #
        # @return [String]
        #
        # @example
        #   Faker::TvShows::Friends.character #=> "Rachel Green"
        #
        # @faker.version 1.7.3
        def character
          fetch('friends.characters')
        end

        ##
        # Produces a location from Friends.
        #
        # @return [String]
        #
        # @example
        #   Faker::TvShows::Friends.location #=> "Central Perk"
        #
        # @faker.version 1.7.3
        def location
          fetch('friends.locations')
        end

        ##
        # Produces a quote from Friends.
        #
        # @return [String]
        #
        # @example
        #   Faker::TvShows::Friends.quote #=> "We were on a break!"
        #
        # @faker.version 1.7.3
        def quote
          fetch('friends.quotes')
        end
      end
    end
  end
end
