# frozen_string_literal: true

module Faker
  class Games
    class WorldOfWarcraft < Base
      class << self
        ##
        # Produces the name of a hero from World of Warcraft.
        #
        # @return [String]
        #
        # @example
        #   Faker::Games::WorldOfWarcraft.hero #=> "Uther the Lightbringer"
        #
        # @faker.version 1.9.2
        def hero
          fetch('games.world_of_warcraft.heros')
        end

        ##
        # Produces a class name from World of Warcraft.
        #
        # @return [String]
        #
        # @example
        #   Faker::Games::WorldOfWarcraft.class_name #=> "Druid"
        #
        # @faker.version next
        def class_name
          fetch('games.world_of_warcraft.class_names')
        end

        # Produces the name of a race from World of Warcraft.
        #
        # @return [String]
        #
        # @example
        #   Faker::Games::WorldOfWarcraft.race #=> "Druid"
        #
        # @faker.version next
        def race
          fetch('games.world_of_warcraft.races')
        end

        ##
        # Produces a quote from World of Warcraft.
        #
        # @return [String]
        #
        # @example
        #   Faker::Games::WorldOfWarcraft.quote #=> "These are dark times indeed."
        #
        # @faker.version 1.9.2
        def quote
          fetch('games.world_of_warcraft.quotes')
        end
      end
    end
  end
end
