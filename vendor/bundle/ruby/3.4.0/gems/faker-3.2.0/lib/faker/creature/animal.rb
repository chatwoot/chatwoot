# frozen_string_literal: true

module Faker
  class Creature
    class Animal < Base
      class << self
        ##
        # Produces a random animal name
        #
        # @return [String]
        #
        # @example
        #   Faker::Creature::Animal.name #=> "fly"
        #
        # @faker.version 1.9.2
        def name
          fetch('creature.animal.name')
        end
      end
    end
  end
end
