# frozen_string_literal: true

module Faker
  class TvShows
    class TheITCrowd < Base
      flexible :the_it_crowd

      class << self
        ##
        # Produces an actor from The IT Crowd.
        #
        # @return [String]
        #
        # @example
        #   Faker::TvShows::TheITCrowd.actor #=> "Chris O'Dowd"
        #
        # @faker.version 1.9.0
        def actor
          fetch('the_it_crowd.actors')
        end

        ##
        # Produces a character from The IT Crowd.
        #
        # @return [String]
        #
        # @example
        #   Faker::TvShows::TheITCrowd.character #=> "Roy Trenneman"
        #
        # @faker.version 1.9.0
        def character
          fetch('the_it_crowd.characters')
        end

        ##
        # Produces an email from The IT Crowd.
        #
        # @return [String]
        #
        # @example
        #   Faker::TvShows::TheITCrowd.email #=> "roy.trenneman@reynholm.test"
        #
        # @faker.version 1.9.0
        def email
          fetch('the_it_crowd.emails')
        end

        ##
        # Produces a quote from The IT Crowd.
        #
        # @return [String]
        #
        # @example
        #   Faker::TvShows::TheITCrowd.quote
        #     #=> "Hello, IT. Have you tried turning it off and on again?"
        #
        # @faker.version 1.9.0
        def quote
          fetch('the_it_crowd.quotes')
        end
      end
    end
  end
end
