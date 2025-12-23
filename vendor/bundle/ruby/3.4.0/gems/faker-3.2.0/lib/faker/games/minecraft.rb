# frozen_string_literal: true

module Faker
  class Games
    class Minecraft < Base
      class << self
        ##
        # Produces the name of an achievement from Minecraft.
        #
        # @return [String]
        #
        # @example
        #   Faker::Games::Minecraft.achievement #=> "Time to Mine!"
        #
        # @faker.version next
        def achievement
          fetch('games.minecraft.achievement')
        end

        ##
        # Produces the name of a biome from Minecraft.
        #
        # @return [String]
        #
        # @example
        #   Faker::Games::Minecraft.biome #=> "Jungle"
        #
        # @faker.version next
        def biome
          fetch('games.minecraft.biome')
        end

        ##
        # Produces the name of a block from Minecraft.
        #
        # @return [String]
        #
        # @example
        #   Faker::Games::Minecraft.block #=> "Stone"
        #
        # @faker.version 2.13.0
        def block
          fetch('games.minecraft.blocks')
        end

        ##
        # Produces the name of a enchantment from Minecraft.
        #
        # @return [String]
        #
        # @example
        #   Faker::Games::Minecraft.enchantment #=> "Fire Protection"
        #
        # @faker.version next
        def enchantment
          fetch('games.minecraft.enchantment')
        end

        ##
        # Produces the name of a game mode from Minecraft.
        #
        # @return [String]
        #
        # @example
        #   Faker::Games::Minecraft.game_mode #=> "Survival"
        #
        # @faker.version next
        def game_mode
          fetch('games.minecraft.game_mode')
        end

        ##
        # Produces the name of an item from Minecraft.
        #
        # @return [String]
        #
        # @example
        #   Faker::Games::Minecraft.item #=> "Iron Shovel"
        #
        # @faker.version 2.13.0
        def item
          fetch('games.minecraft.items')
        end

        ##
        # Produces the name of a mob from Minecraft.
        #
        # @return [String]
        #
        # @example
        #   Faker::Games::Minecraft.mob #=> "Sheep"
        #
        # @faker.version 2.13.0
        def mob
          fetch('games.minecraft.mobs')
        end

        ##
        # Produces the name of a status effect from Minecraft.
        #
        # @return [String]
        #
        # @example
        #   Faker::Games::Minecraft.status_effect #=> "Weakness"
        #
        # @faker.version next
        def status_effect
          fetch('games.minecraft.status_effect')
        end
      end
    end
  end
end
