# frozen_string_literal: true

module Faker
  class Books
    class TheKingkillerChronicle < Base
      class << self
        ##
        # Produces the name of a The Kingkiller Chronicle book.
        #
        # @return [String]
        #
        # @example
        #   Faker::Books::TheKingkillerChronicle.book #=> "The Name of the Wind"
        #
        # @faker.version next
        def book
          fetch('books.the_kingkiller_chronicle.books')
        end

        ##
        # Produces the name of a The Kingkiller Chronicle character.
        #
        # @return [String]
        #
        # @example
        #   Faker::Books::TheKingkillerChronicle.character #=> "Kvothe"
        #
        # @faker.version next
        def character
          fetch('books.the_kingkiller_chronicle.characters')
        end

        ##
        # Produces the name of a The Kingkiller Chronicle creature.
        #
        # @return [String]
        #
        # @example
        #   Faker::Books::TheKingkillerChronicle.creature #=> "Scrael"
        #
        # @faker.version next
        def creature
          fetch('books.the_kingkiller_chronicle.creatures')
        end

        ##
        # Produces the name of a The Kingkiller Chronicle location.
        #
        # @return [String]
        #
        # @example
        #   Faker::Books::TheKingkillerChronicle.location #=> "Tarbean"
        #
        # @faker.version next
        def location
          fetch('books.the_kingkiller_chronicle.locations')
        end
      end
    end
  end
end
