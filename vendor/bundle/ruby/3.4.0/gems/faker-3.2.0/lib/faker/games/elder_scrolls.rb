# frozen_string_literal: true

module Faker
  class Games
    class ElderScrolls < Base
      class << self
        ##
        # Produces the name of a race from the Elder Scrolls universe.
        #
        # @return [String]
        #
        # @example
        #   Faker::Games::ElderScrolls.race #=> "Argonian"
        #
        # @faker.version 1.9.2
        def race
          fetch('games.elder_scrolls.race')
        end

        ##
        # Produces the name of a city from the Elder Scrolls universe.
        #
        # @return [String]
        #
        # @example
        #   Faker::Games::ElderScrolls.city #=> "Whiterun"
        #
        # @faker.version 1.9.2
        def city
          fetch('games.elder_scrolls.city')
        end

        ##
        # Produces the name of a creature from the Elder Scrolls universe.
        #
        # @return [String]
        #
        # @example
        #   Faker::Games::ElderScrolls.creature #=> "Frost Troll"
        #
        # @faker.version 1.9.2
        def creature
          fetch('games.elder_scrolls.creature')
        end

        ##
        # Produces the name of a region from the Elder Scrolls universe.
        #
        # @return [String]
        #
        # @example
        #   Faker::Games::ElderScrolls.region #=> "Cyrodiil"
        #
        # @faker.version 1.9.2
        def region
          fetch('games.elder_scrolls.region')
        end

        ##
        # Produces the name of a dragon from the Elder Scrolls universe.
        #
        # @return [String]
        #
        # @example
        #   Faker::Games::ElderScrolls.dragon #=> "Blood Dragon"
        #
        # @faker.version 1.9.2
        def dragon
          fetch('games.elder_scrolls.dragon')
        end

        ##
        # Produces a randomly generated name from the Elder Scrolls universe.
        #
        # @return [String]
        #
        # @example
        #   Faker::Games::ElderScrolls.name #=> "Balgruuf The Old"
        #
        # @faker.version 1.9.2
        def name
          "#{fetch('games.elder_scrolls.first_name')} #{fetch('games.elder_scrolls.last_name')}"
        end

        ##
        # Produces a first name from the Elder Scrolls universe.
        #
        # @return [String]
        #
        # @example
        #   Faker::Games::ElderScrolls.first_name #=> "Balgruuf"
        #
        # @faker.version 1.9.2
        def first_name
          fetch('games.elder_scrolls.first_name')
        end

        ##
        # Produces a last name from the Elder Scrolls universe.
        #
        # @return [String]
        #
        # @example
        #   Faker::Games::ElderScrolls.last_name #=> "The Old"
        #
        # @faker.version 1.9.2
        def last_name
          fetch('games.elder_scrolls.last_name')
        end

        ##
        # Produces a weapon from the Elder Scrolls universe.
        #
        # @return [String]
        #
        # @example
        #   Faker::Games::ElderScrolls.weapon #=> "Elven Bow"
        #
        # @faker.version next
        def weapon
          fetch('games.elder_scrolls.weapon')
        end

        ##
        # Produces a weapon from the Elder Scrolls universe.
        #
        # @return [String]
        #
        # @example
        #   Faker::Games::ElderScrolls.jewelry #=> "Silver Ruby Ring"
        #
        # @faker.version next
        def jewelry
          fetch('games.elder_scrolls.jewelry')
        end
      end
    end
  end
end
