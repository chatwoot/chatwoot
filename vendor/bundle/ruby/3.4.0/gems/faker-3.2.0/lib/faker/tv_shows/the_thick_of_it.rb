# frozen_string_literal: true

module Faker
  class TvShows
    class TheThickOfIt < Base
      flexible :the_thick_of_it

      class << self
        ##
        # Produces a character from The Thick of It.
        #
        # @return [String]
        #
        # @example
        #   Faker::TvShows::TheThickOfIt.character #=> "Nicola Murray"
        #
        # @faker.version 1.8.5
        def character
          fetch('the_thick_of_it.characters')
        end

        ##
        # Produces a department from The Thick of It.
        #
        # @return [String]
        #
        # @example
        #   Faker::TvShows::TheThickOfIt.department #=> "Shadow Cabinet"
        #
        # @faker.version 1.8.5
        def department
          fetch('the_thick_of_it.departments')
        end

        ##
        # Produces a position from The Thick of It.
        #
        # @return [String]
        #
        # @example
        #   Faker::TvShows::TheThickOfIt.position
        #     #=> "Director of Communications"
        #
        # @faker.version 1.8.5
        def position
          fetch('the_thick_of_it.positions')
        end
      end
    end
  end
end
