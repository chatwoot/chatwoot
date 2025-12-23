# frozen_string_literal: true

module Faker
  class TvShows
    class FamilyGuy < Base
      flexible :family_guy

      class << self
        ##
        # Produces a character from Family Guy.
        #
        # @return [String]
        #
        # @example
        #   Faker::TvShows::FamilyGuy.character #=> "Peter Griffin"
        #
        # @faker.version 1.8.0
        def character
          fetch('family_guy.character')
        end

        ##
        # Produces a location from Family Guy.
        #
        # @return [String]
        #
        # @example
        #   Faker::TvShows::FamilyGuy.location #=> "James Woods High"
        #
        # @faker.version 1.8.0
        def location
          fetch('family_guy.location')
        end

        ##
        # Produces a quote from Family Guy.
        #
        # @return [String]
        #
        # @example
        #   Faker::TvShows::FamilyGuy.quote
        #     #=> "It's Peanut Butter Jelly Time."
        #
        # @faker.version 1.8.0
        def quote
          fetch('family_guy.quote')
        end
      end
    end
  end
end
