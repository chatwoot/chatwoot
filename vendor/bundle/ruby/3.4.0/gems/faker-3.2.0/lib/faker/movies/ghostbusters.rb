# frozen_string_literal: true

module Faker
  class Movies
    class Ghostbusters < Base
      class << self
        ##
        # Produces an actor from Ghostbusters.
        #
        # @return [String]
        #
        # @example
        #   Faker::Movies::Ghostbusters.actor #=> "Bill Murray"
        #
        # @faker.version 1.9.2
        def actor
          fetch('ghostbusters.actors')
        end

        ##
        # Produces a character from Ghostbusters.
        #
        # @return [String]
        #
        # @example
        #   Faker::Movies::Ghostbusters.character #=> "Dr. Egon Spengler"
        #
        # @faker.version 1.9.2
        def character
          fetch('ghostbusters.characters')
        end

        ##
        # Produces a quote from Ghostbusters.
        #
        # @return [String]
        #
        # @example
        #   Faker::Movies::Ghostbusters.quote
        #     #=> "I tried to think of the most harmless thing. Something I loved from my childhood. Something that could never ever possibly destroy us. Mr. Stay Puft!"
        #
        # @faker.version 1.9.2
        def quote
          fetch('ghostbusters.quotes')
        end
      end
    end
  end
end
