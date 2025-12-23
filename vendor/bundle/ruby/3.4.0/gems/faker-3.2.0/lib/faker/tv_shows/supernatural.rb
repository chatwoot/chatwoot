# frozen_string_literal: true

module Faker
  class TvShows
    class Supernatural < Base
      class << self
        ##
        # Produces the name of a character from Supernatural.
        #
        # @return [String]
        #
        # @example
        #   Faker::TvShows::Supernatural.character #=> "Dean Winchester"
        #
        # @faker.version next
        def character
          fetch('supernatural.character')
        end

        ##
        # Produces the name of a hunted creature.
        #
        # @return [String]
        #
        # @example
        #   Faker::TvShows::Supernatural.creature #=> "Demon"
        #
        # @faker.version next
        def creature
          fetch('supernatural.creature')
        end

        ##
        # Produces the name of a weapon used by the hunters.
        #
        # @return [String]
        #
        # @example
        #   Faker::TvShows::Supernatural.weapon #=> "Colt"
        #
        # @faker.version next
        def weapon
          fetch('supernatural.weapon')
        end
      end
    end
  end
end
