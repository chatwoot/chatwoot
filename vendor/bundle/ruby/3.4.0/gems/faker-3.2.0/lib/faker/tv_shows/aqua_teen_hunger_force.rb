# frozen_string_literal: true

module Faker
  class TvShows
    class AquaTeenHungerForce < Base
      flexible :aqua_teen_hunger_force

      class << self
        ##
        # Produces a character from Aqua Teen Hunger Force.
        #
        # @return [String]
        #
        # @example
        #   Faker::TvShows::AquaTeenHungerForce.character #=> "Master Shake"
        #
        # @faker.version 1.8.5
        def character
          fetch('aqua_teen_hunger_force.character')
        end

        ##
        # Produces a perl of great ATHF wisdom
        #
        # @return [String]
        #
        # @example
        #   Faker::TvShows::AquaTeenHungerForce.quote #=> "Friendship ain't about trust. Friendship's about nunchucks."
        #
        # @faker.version 2.13.0
        def quote
          fetch('aqua_teen_hunger_force.quote')
        end
      end
    end
  end
end
