# frozen_string_literal: true

module Faker
  class Games
    class Overwatch < Base
      class << self
        ##
        # Produces the name of a hero from Overwatch.
        #
        # @return [String]
        #
        # @example
        #   Faker::Games::Overwatch.hero #=> "Tracer"
        #
        # @faker.version 1.8.0
        def hero
          fetch('games.overwatch.heroes')
        end

        ##
        # Produces the name of a location from Overwatch.
        #
        # @return [String]
        #
        # @example
        #   Faker::Games::Overwatch.location #=> "Numbani"
        #
        # @faker.version 1.8.0
        def location
          fetch('games.overwatch.locations')
        end

        ##
        # Produces a quote from Overwatch.
        #
        # @return [String]
        #
        # @example
        #   Faker::Games::Overwatch.quote #=> "It's high noon"
        #
        # @faker.version 1.8.0
        def quote
          fetch('games.overwatch.quotes')
        end
      end
    end
  end
end
