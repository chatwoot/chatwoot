# frozen_string_literal: true

module Faker
  class TvShows
    class TheOffice < Base
      flexible :the_office

      class << self
        ##
        # Produces a character from The Office.
        #
        # @return [String]
        #
        # @example
        #   Faker::TvShows::TheOffice.character #=> "Michael Scott"
        #
        # @faker.version next
        def character
          fetch('the_office.characters')
        end

        ##
        # Produces a quote from The Office.
        #
        # @return [String]
        #
        # @example
        #   Faker::TvShows::TheOffice.quote #=> "Identity theft is not a joke, Jim! Millions of families suffer every year."
        #
        # @faker.version next
        def quote
          fetch('the_office.quotes')
        end
      end
    end
  end
end
