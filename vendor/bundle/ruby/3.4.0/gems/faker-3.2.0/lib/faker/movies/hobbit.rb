# frozen_string_literal: true

module Faker
  class Movies
    class Hobbit < Base
      class << self
        ##
        # Produces the name of a character from The Hobbit.
        #
        # @return [String]
        #
        # @example
        #   Faker::Movies::Hobbit.character #=> "Gandalf the Grey"
        #
        # @faker.version 1.8.0
        def character
          fetch('tolkien.hobbit.character')
        end

        ##
        # Produces the name of one of the 13 dwarves from the Company, or Gandalf or Bilbo.
        #
        # @return [String]
        #
        # @example
        #   Faker::Movies::Hobbit.thorins_company #=> "Thorin Oakenshield"
        #
        # @faker.version 1.8.0
        def thorins_company
          fetch('tolkien.hobbit.thorins_company')
        end

        ##
        # Produces a quote from The Hobbit.
        #
        # @return [String]
        #
        # @example
        #   Faker::Movies::Hobbit.quote
        #     #=> "Never laugh at live dragons, Bilbo you fool!"
        #
        # @faker.version 1.8.0
        def quote
          fetch('tolkien.hobbit.quote')
        end

        ##
        # Produces the name of a location from The Hobbit.
        #
        # @return [String]
        #
        # @example
        #   Faker::Movies::Hobbit.location #=> "The Shire"
        #
        # @faker.version 1.8.0
        def location
          fetch('tolkien.hobbit.location')
        end
      end
    end
  end
end
