# frozen_string_literal: true

module Faker
  class Games
    class Touhou < Base
      flexible :touhou
      class << self
        ##
        # Produces the name of a Touhou game.
        #
        # @return [String]
        #
        # @example
        #   Faker::Games::Touhou.game #=> "Mountain of Faith"
        #
        # @faker.version next
        def game
          fetch('games.touhou.games')
        end

        ##
        # Produces the name of a character from the Touhou games.
        #
        # @return [String]
        #
        # @example
        #   Faker::Games::Touhou.character #=> "Sanae Kochiya"
        #
        # @faker.version next
        def character
          fetch('games.touhou.characters')
        end

        ##
        # Produces the name of a location from the Touhou games.
        #
        # @return [String]
        #
        # @example
        #   Faker::Games::Touhou.location #=> "Moriya Shrine"
        #
        # @faker.version next
        def location
          fetch('games.touhou.locations')
        end

        ##
        # Produces the name of a spell card from the Touhou games.
        #
        # @return [String]
        #
        # @example
        #   Faker::Games::Touhou.spell_card #=> 'Esoterica "Gray Thaumaturgy"'
        #
        # @faker.version next
        def spell_card
          fetch('games.touhou.spell_cards')
        end

        ##
        # Produces the name of a song from the Touhou games.
        #
        # @return [String]
        #
        # @example
        #   Faker::Games::Touhou.song #=> "Faith Is for the Transient People"
        #
        # @faker.version next
        def song
          fetch('games.touhou.songs')
        end
      end
    end
  end
end
