# frozen_string_literal: true

module Faker
  class Movies
    class HarryPotter < Base
      class << self
        ##
        # Produces a character from Harry Potter.
        #
        # @return [String]
        #
        # @example
        #   Faker::Movies::HarryPotter.character #=> "Harry Potter"
        #
        # @faker.version 1.7.3
        def character
          fetch('harry_potter.characters')
        end

        ##
        # Produces a location from Harry Potter.
        #
        # @return [String]
        #
        # @example
        #   Faker::Movies::HarryPotter.location #=> "Hogwarts"
        #
        # @faker.version 1.7.3
        def location
          fetch('harry_potter.locations')
        end

        ##
        # Produces a quote from Harry Potter.
        #
        # @return [String]
        #
        # @example
        #   Faker::Movies::HarryPotter.quote #=> "I solemnly swear that I am up to good."
        #
        # @faker.version 1.7.3
        def quote
          fetch('harry_potter.quotes')
        end

        ##
        # Produces a book from Harry Potter.
        #
        # @return [String]
        #
        # @example
        #   Faker::Movies::HarryPotter.book #=> "Harry Potter and the Chamber of Secrets"
        #
        # @faker.version 1.7.3
        def book
          fetch('harry_potter.books')
        end

        ##
        # Produces a house from Harry Potter.
        #
        # @return [String]
        #
        # @example
        #   Faker::Movies::HarryPotter.house #=> "Gryffindor"
        #
        # @faker.version 1.7.3
        def house
          fetch('harry_potter.houses')
        end

        ##
        # Produces a spell from Harry Potter.
        #
        # @return [String]
        #
        # @example
        #   Faker::Movies::HarryPotter.spell #=> "Reparo"
        #
        # @faker.version 1.7.3
        def spell
          fetch('harry_potter.spells')
        end
      end
    end
  end
end
