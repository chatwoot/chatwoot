# frozen_string_literal: true

module Faker
  class Movies
    class Hackers < Base
      class << self
        ##
        # Produces a real character name from Hackers.
        #
        # @return [String]
        #
        # @example
        #   Faker::Movies::Hackers.character #=> "Dade Murphy"
        #
        # @faker.version next
        def character
          fetch('hackers.characters')
        end

        ##
        # Produces a character hacker "handle" from Hackers.
        #
        # @return [String]
        #
        # @example
        #   Faker::Movies::Hackers.handle #=> "Zero Cool"
        #
        # @faker.version next
        def handle
          fetch('hackers.handles')
        end

        ##
        # Produces a quote from Hackers.
        #
        # @return [String]
        #
        # @example
        #   Faker::Movies::Hackers.quote #=> "Hack the Planet!"
        #
        # @faker.version next
        def quote
          fetch('hackers.quotes')
        end
      end
    end
  end
end
