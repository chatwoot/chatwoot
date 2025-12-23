# frozen_string_literal: true

module Faker
  class Creature
    class Dog < Base
      flexible :dog

      class << self
        ##
        # Produces a random name for a dog
        #
        # @return [String]
        #
        # @example
        #   Faker::Creature::Dog.name #=> "Spike"
        #
        # @faker.version 1.9.2
        def name
          fetch('creature.dog.name')
        end

        ##
        # Produces a random dog breed
        #
        # @return [String]
        #
        # @example
        #   Faker::Creature::Dog.breed #=> "Yorkshire Terrier"
        #
        # @faker.version 1.9.2
        def breed
          fetch('creature.dog.breed')
        end

        ##
        # Produces a random sound made by a dog
        #
        # @return [String]
        #
        # @example
        #   Faker::Creature::Dog.sound #=> "woof woof"
        #
        # @faker.version 1.9.2
        def sound
          fetch('creature.dog.sound')
        end

        ##
        # Produces a random dog meme phrase
        #
        # @return [String]
        #
        # @example
        #   Faker::Creature::Dog.meme_phrase #=> "smol pupperino"
        #
        # @faker.version 1.9.2
        def meme_phrase
          fetch('creature.dog.meme_phrase')
        end

        ##
        # Produces a random dog age
        #
        # @return [String]
        #
        # @example
        #   Faker::Creature::Dog.age #=> "puppy"
        #
        # @faker.version 1.9.2
        def age
          fetch('creature.dog.age')
        end

        ##
        # Produces a random gender
        #
        # @return [String]
        #
        # @example
        #   Faker::Creature::Dog.gender #=> "Female"
        #
        # @faker.version 1.9.2
        def gender
          Faker::Gender.binary_type
        end

        ##
        # Produces a random coat length
        #
        # @return [String]
        #
        # @example
        #   Faker::Creature::Dog.coat_length #=> "short"
        #
        # @faker.version 1.9.2
        def coat_length
          fetch('creature.dog.coat_length')
        end

        ##
        # Produces a random size of a dog
        #
        # @return [String]
        #
        # @example
        #   Faker::Creature::Dog.size #=> "small"
        #
        # @faker.version 1.9.2
        def size
          fetch('creature.dog.size')
        end
      end
    end
  end
end
