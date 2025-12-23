# frozen_string_literal: true

module Faker
  class Games
    class Tarkov < Base
      class << self
        ##
        # Produces a random location from Escape from Tarkov.
        #
        # @return [String]
        #
        # @example
        #   Faker::Games::Tarkov.location #=> "Customs"
        #
        # @faker.version next
        def location
          fetch('tarkov.locations')
        end

        ##
        # Produces a random trader from Escape from Tarkov.
        #
        # @return [String]
        #
        # @example
        #   Faker::Games::Tarkov.trader #=> "Prapor"
        #
        # @faker.version next
        def trader
          fetch('tarkov.traders')
        end

        ##
        # Produces a random item from Escape from Tarkov.
        #
        # @return [String]
        #
        # @example
        #   Faker::Games::Tarkov.item #=> "Diary"
        #
        # @faker.version next
        def item
          fetch('tarkov.items')
        end

        ##
        # Produces a random weapon from Escape from Tarkov.
        #
        # @return [String]
        #
        # @example
        #   Faker::Games::Tarkov.weapon #=> "AK-74N"
        #
        # @faker.version next
        def weapon
          fetch('tarkov.weapons')
        end

        ##
        # Produces a random boss from Escape from Tarkov.
        #
        # @return [String]
        #
        # @example
        #   Faker::Games::Tarkov.boss #=> "Tagilla"
        #
        # @faker.version next
        def boss
          fetch('tarkov.bosses')
        end

        ##
        # Produces a random faction from Escape from Tarkov.
        #
        # @return [String]
        #
        # @example
        #   Faker::Games::Tarkov.faction #=> "USEC"
        #
        # @faker.version next
        def faction
          fetch('tarkov.factions')
        end

        ##
        # Produces a random quest from a random trader from Escape from Tarkov.
        #
        # @return [String]
        #
        # @example
        #   Faker::Games::Tarkov.quest #=> "The Key to Success"
        #
        # @faker.version next
        def quest
          @traders = %w[prapor therapist skier peacekeeper mechanic ragman jaeger fence]
          fetch("tarkov.quests.#{@traders.sample}")
        end

        ##
        # Produces a random quest from Prapor from Escape from Tarkov.
        #
        # @return [String]
        #
        # @example
        #   Faker::Games::Tarkov.prapor_quest #=> "Easy Job - Part 2
        #
        # @faker.version next
        def prapor_quest
          fetch('tarkov.quests.prapor')
        end

        ##
        # Produces a random quest from Therapist from Escape from Tarkov.
        #
        # @return [String]
        #
        # @example
        #   Faker::Games::Tarkov.therapist_quest #=> "Supply Plans"
        #
        # @faker.version next
        def therapist_quest
          fetch('tarkov.quests.therapist')
        end

        ##
        # Produces a random quest from Skier from Escape from Tarkov.
        #
        # @return [String]
        #
        # @example
        #   Faker::Games::Tarkov.skier_quest #=> "Safe Corridor"
        #
        # @faker.version next
        def skier_quest
          fetch('tarkov.quests.skier')
        end

        ##
        # Produces a random quest from Peacekeeper from Escape from Tarkov.
        #
        # @return [String]
        #
        # @example
        #   Faker::Games::Tarkov.peacekeeper_quest #=> "Overpopulation"
        #
        # @faker.version next
        def peacekeeper_quest
          fetch('tarkov.quests.peacekeeper')
        end

        ##
        # Produces a random quest from Mechanic from Escape from Tarkov.
        #
        # @return [String]
        #
        # @example
        #   Faker::Games::Tarkov.mechanic_quest #=> "Signal - Part 4"
        #
        # @faker.version next
        def mechanic_quest
          fetch('tarkov.quests.mechanic')
        end

        ##
        # Produces a random quest from Ragman from Escape from Tarkov.
        #
        # @return [String]
        #
        # @example
        #   Faker::Games::Tarkov.ragman_quest #=> "Hot Delivery"
        #
        # @faker.version next
        def ragman_quest
          fetch('tarkov.quests.ragman')
        end

        ##
        # Produces a random quest from Jaeger from Escape from Tarkov.
        #
        # @return [String]
        #
        # @example
        #   Faker::Games::Tarkov.jaeger_quest #=> "The Tarkov Shooter - Part 1"
        #
        # @faker.version next
        def jaeger_quest
          fetch('tarkov.quests.jaeger')
        end

        ##
        # Produces a random quest from Fence from Escape from Tarkov.
        #
        # @return [String]
        #
        # @example
        #   Faker::Games::Tarkov.fence_quest #=> "Compensation for Damage - Wager"
        #
        # @faker.version next
        def fence_quest
          fetch('tarkov.quests.fence')
        end
      end
    end
  end
end
