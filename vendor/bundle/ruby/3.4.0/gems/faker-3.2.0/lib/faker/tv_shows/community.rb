# frozen_string_literal: true

module Faker
  class TvShows
    class Community < Base
      flexible :community

      class << self
        ##
        # Produces a character from Community.
        #
        # @return [String]
        #
        # @example
        #   Faker::TvShows::Community.characters #=> "Jeff Winger"
        #
        # @faker.version 1.9.0
        def characters
          fetch('community.characters')
        end

        ##
        # Produces a quote from Community.
        #
        # @return [String]
        #
        # @example
        #   Faker::TvShows::Community.quotes
        #     #=> "I fear a political career could shine a negative light on my drug dealing."
        #
        # @faker.version 1.9.0
        def quotes
          fetch('community.quotes')
        end
      end
    end
  end
end
