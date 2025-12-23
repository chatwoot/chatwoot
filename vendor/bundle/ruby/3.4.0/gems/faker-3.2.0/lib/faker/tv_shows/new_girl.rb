# frozen_string_literal: true

module Faker
  class TvShows
    class NewGirl < Base
      flexible :new_girl

      class << self
        ##
        # Produces a character from New Girl.
        #
        # @return [String]
        #
        # @example
        #   Faker::TvShows::NewGirl.character #=> "Jessica Day"
        #
        # @faker.version 1.9.0
        def character
          fetch('new_girl.characters')
        end

        ##
        # Produces a quote from New Girl.
        #
        # @return [String]
        #
        # @example
        #   Faker::TvShows::NewGirl.quote
        #     #=> "Are you cooking a frittata in a sauce pan? What is this - prison?"
        #
        # @faker.version 1.9.0
        def quote
          fetch('new_girl.quotes')
        end
      end
    end
  end
end
