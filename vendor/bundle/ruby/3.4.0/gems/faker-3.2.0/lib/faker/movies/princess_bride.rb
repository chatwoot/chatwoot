# frozen_string_literal: true

module Faker
  class Movies
    class PrincessBride < Base
      class << self
        ##
        # Produces a character from The Princess Bride.
        #
        # @return [String]
        #
        # @example
        #   Faker::Movies::PrincessBride.character #=> "Dread Pirate Roberts"
        #
        # @faker.version 1.9.0
        def character
          fetch('princess_bride.characters')
        end

        ##
        # Produces a quote from The Princess Bride.
        #
        # @return [String]
        #
        # @example
        #   Faker::Movies::PrincessBride.quote
        #     #=> "Hello. My name is Inigo Montoya. You killed my father. Prepare to die!"
        #
        # @faker.version 1.9.0
        def quote
          fetch('princess_bride.quotes')
        end
      end
    end
  end
end
