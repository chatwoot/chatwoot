# frozen_string_literal: true

module Faker
  class TvShows
    class FinalSpace < Base
      flexible :final_space

      class << self
        ##
        # Produces a character from Final Space.
        #
        # @return [String]
        #
        # @example
        #   Faker::TvShows::FinalSpace.character #=> "Gary Goodspeed"
        #
        # @faker.version next
        def character
          fetch('final_space.characters')
        end

        ##
        # Produces a vehicle from Final Space.
        #
        # @return [String]
        #
        # @example
        #   Faker::TvShows::FinalSpace.vehicle #=> "Imperium Cruiser"
        #
        # @faker.version next
        def vehicle
          fetch('final_space.vehicles')
        end

        ##
        # Produces a quote from Final Space.
        #
        # @return [String]
        #
        # @example
        #   Faker::TvShows::FinalSpace.quote
        #     #=> "It's an alien on my face! It's an alien on my...It's a space alien!"
        #
        # @faker.version next
        def quote
          fetch('final_space.quotes')
        end
      end
    end
  end
end
