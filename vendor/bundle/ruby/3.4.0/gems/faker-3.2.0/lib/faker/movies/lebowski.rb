# frozen_string_literal: true

module Faker
  class Movies
    class Lebowski < Base
      class << self
        ##
        # Produces an actor from The Big Lebowski.
        #
        # @return [String]
        #
        # @example
        #   Faker::Movies::Lebowski.actor #=> "John Goodman"
        #
        # @faker.version 1.8.8
        def actor
          fetch('lebowski.actors')
        end

        ##
        # Produces a character from The Big Lebowski.
        #
        # @return [String]
        #
        # @example
        #   Faker::Movies::Lebowski.character #=> "Jackie Treehorn"
        #
        # @faker.version 1.8.8
        def character
          fetch('lebowski.characters')
        end

        ##
        # Produces a quote from The Big Lebowski.
        #
        # @return [String]
        #
        # @example
        #   Faker::Movies::Lebowski.quote #=> "Forget it, Donny, you're out of your element!"
        #
        # @faker.version 1.8.8
        def quote
          fetch('lebowski.quotes')
        end
      end
    end
  end
end
