# frozen_string_literal: true

module Faker
  class Movies
    class HowToTrainYourDragon < Base
      class << self
        ##
        # Produces a character from How To Train Your Dragon.
        #
        # @return [String]
        #
        # @example
        #   Faker::Movies::HowToTrainYourDragon.character #=> "Hiccup"
        #
        # @faker.version next
        def character
          fetch('how_to_train_your_dragon.characters')
        end

        ##
        # Produces a location from How To Train Your Dragon.
        #
        # @return [String]
        #
        # @example
        #   Faker::Movies::HowToTrainYourDragon.location #=> "Berk"
        #
        # @faker.version next
        def location
          fetch('how_to_train_your_dragon.locations')
        end

        ##
        # Produces a dragon from How To Train Your Dragon.
        #
        # @return [String]
        #
        # @example
        #   Faker::Movies::HowToTrainYourDragon.dragons #=> "Toothless"
        #
        # @faker.version next
        def dragon
          fetch('how_to_train_your_dragon.dragons')
        end
      end
    end
  end
end
