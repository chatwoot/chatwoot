# frozen_string_literal: true

module Faker
  class Movies
    class Departed < Base
      class << self
        ##
        # Produces an actor from The Departed.
        #
        # @return [String]
        #
        # @example
        #   Faker::Movies::Departed.actor #=> "Matt Damon"
        #
        # @faker.version 2.13.0
        def actor
          fetch('departed.actors')
        end

        ##
        # Produces a character from The Departed.
        #
        # @return [String]
        #
        # @example
        #   Faker::Movies::Departed.character #=> "Frank Costello"
        #
        # @faker.version 2.13.0
        def character
          fetch('departed.characters')
        end

        ##
        # Produces a quote from The Departed.
        #
        # @return [String]
        #
        # @example
        #   Faker::Movies::Departed.quote
        #     #=> "I'm the guy who does his job. You must be the other guy"
        #
        # @faker.version 2.13.0
        def quote
          fetch('departed.quotes')
        end
      end
    end
  end
end
