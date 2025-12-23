# frozen_string_literal: true

module Faker
  class Creature
    class Cat < Base
      flexible :cat

      class << self
        ##
        # Produces a random name for a cat
        #
        # @return [String]
        #
        # @example
        #   Faker::Creature::Cat.name #=> "Felix"
        #
        # @faker.version 1.9.2
        def name
          fetch('creature.cat.name')
        end

        ##
        # Produces a random cat breed
        #
        # @return [String]
        #
        # @example
        #   Faker::Creature::Cat.breed #=> "Scottish Fold"
        #
        # @faker.version 1.9.2
        def breed
          fetch('creature.cat.breed')
        end

        ##
        # Produces a random cat breed registry
        #
        # @return [String]
        #
        # @example
        #   Faker::Creature::Cat.registry #=> "Fancy Southern Africa Cat Council"
        #
        # @faker.version 1.9.2
        def registry
          fetch('creature.cat.registry')
        end
      end
    end
  end
end
