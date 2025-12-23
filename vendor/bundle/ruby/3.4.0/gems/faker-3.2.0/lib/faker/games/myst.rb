# frozen_string_literal: true

module Faker
  class Games
    class Myst < Base
      class << self
        ##
        # Produces the name of a game from the Myst series.
        #
        # @return [String]
        #
        # @example
        #   Faker::Games::Myst.game #=> "Myst III: Exile"
        #
        # @faker.version 1.9.0
        def game
          fetch('games.myst.games')
        end

        ##
        # Produces the name of a creature from Myst.
        #
        # @return [String]
        #
        # @example
        #   Faker::Games::Myst.creature #=> "squee"
        #
        # @faker.version 1.9.0
        def creature
          fetch('games.myst.creatures')
        end

        ##
        # Produces the name of an age from Myst.
        #
        # @return [String]
        #
        # @example
        #   Faker::Games::Myst.age #=> "Relto"
        #
        # @faker.version 1.9.0
        def age
          fetch('games.myst.ages')
        end

        ##
        # Produces the name of a character from Myst.
        #
        # @return [String]
        #
        # @example
        #   Faker::Games::Myst.character #=> "Gehn"
        #
        # @faker.version 1.9.0
        def character
          fetch('games.myst.characters')
        end

        ##
        # Produces a quote from Myst.
        #
        # @return [String]
        #
        # @example
        #   Faker::Games::Myst.quote #=> "I realized, the moment I fell into the fissure, that the Book would not be destroyed as I had planned."
        #
        # @faker.version 1.9.0
        def quote
          fetch('games.myst.quotes')
        end
      end
    end
  end
end
