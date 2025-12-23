# frozen_string_literal: true

module Faker
  class Games
    class Control < Base
      class << self
        ##
        # Produces the name of a character from Control.
        #
        # @return [String]
        #
        # @example
        #   Faker::Games::Control.character #=> "Jesse Faden"
        #
        # @faker.version 2.13.0
        def character
          fetch('games.control.character')
        end

        ##
        # Produces the name of a location from Control.
        #
        # @return [String]
        #
        # @example
        #   Faker::Games::Control.location #=> "Dimensional Research"
        #
        # @faker.version 2.13.0
        def location
          fetch('games.control.location')
        end

        ##
        # Produces the name of an Object of Power (OoP)
        #
        # @return [String]
        #
        # @example
        #   Faker::Games::Control.object_of_power #=> "Hotline"
        #
        # @faker.version 2.13.0
        def object_of_power
          fetch('games.control.object_of_power')
        end

        ##
        # Produces the name of an Altered Item
        #
        # @return [String]
        #
        # @example
        #   Faker::Games::Control.altered_item #=> "Rubber Duck"
        #
        # @faker.version 2.13.0
        def altered_item
          fetch('games.control.altered_item')
        end

        ##
        # Produces the location of an Altered World Event (AWE)
        #
        # @return [String]
        #
        # @example
        #   Faker::Games::Control.altered_world_event #=> "Ordinary, Wisconsin"
        #
        # @faker.version 2.13.0
        def altered_world_event
          fetch('games.control.altered_world_event')
        end

        ##
        # Produces a line from the Hiss incantation
        #
        # @return [String]
        #
        # @example
        #   Faker::Games::Control.hiss #=> "Push the fingers through the surface into the wet."
        #
        # @faker.version 2.13.0
        def hiss
          fetch('games.control.hiss')
        end

        ##
        # < Produces a line/quote/message from The Board >
        #
        # @return [String]
        #
        # @example
        #   Faker::Games::Control.the_board #=> "< You/We wield the Gun/You. The Board appoints you. Congratulations, Director. >"
        #
        # @faker.version 2.13.0
        def the_board
          fetch('games.control.the_board')
        end

        ##
        # Produces a quote from Control
        #
        # @return [String]
        #
        # @example
        #   Faker::Games::Control.quote #=> "He never liked fridge duty"
        #
        # @faker.version 2.13.0
        def quote
          fetch('games.control.quote')
        end
      end
    end
  end
end
