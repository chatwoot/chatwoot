# frozen_string_literal: true

module Faker
  class Movies
    class TheRoom < Base
      class << self
        ##
        # Produces an actor from The Room (2003).
        #
        # @return [String]
        #
        # @example
        #   Faker::Movies::Room.actor #=> "Tommy Wiseau"
        #
        # @faker.version next
        def actor
          fetch('room.actors')
        end

        ##
        # Produces a character from The Room (2003).
        #
        # @return [String]
        #
        # @example
        #   Faker::Movies::Room.character #=> "Johnny"
        #
        # @faker.version next
        def character
          fetch('room.characters')
        end

        ##
        # Produces a location from The Room (2003).
        #
        # @return [String]
        #
        # @example
        #   Faker::Movies::Room.location #=> "Johnny's Apartment"
        #
        # @faker.version next
        def location
          fetch('room.locations')
        end

        ##
        ##
        # Produces a quote from The Room (2003).
        #
        # @return [String]
        #
        # @example
        #   Faker::Movies::Room.quote
        #     #=> "You're lying, I never hit you. You are tearing me apart, Lisa!"
        #
        # @faker.version next
        def quote
          fetch('room.quotes')
        end
      end
    end
  end
end
