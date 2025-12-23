# frozen_string_literal: true

module Faker
  class Games
    class Heroes < Base
      class << self
        ##
        # Produces the name of a hero from Heroes 3.
        #
        # @return [String]
        #
        # @example
        #   Faker::Games::Heroes.name #=> "Christian"
        #
        # @faker.version 1.9.2
        def name
          fetch('heroes.names')
        end

        ##
        # Produces the name of a specialty from Heroes 3.
        #
        # @return [String]
        #
        # @example
        #   Faker::Games::Heroes.specialty #=> "Ballista"
        #
        # @faker.version 1.9.2
        def specialty
          fetch('heroes.specialties')
        end

        ##
        # Produces the name of a class from Heroes 3.
        #
        # @return [String]
        #
        # @example
        #   Faker::Games::Heroes.klass #=> "Knight"
        #
        # @faker.version 1.9.2
        def klass
          fetch('heroes.klasses')
        end

        ##
        # Produces the name of an artifact from Heroes 3.
        #
        # @return [String]
        #
        # @example
        #   Faker::Games::Heroes.artifact #=> "Armageddon's Blade"
        #
        # @faker.version next
        def artifact
          fetch('heroes.artifacts')
        end
      end
    end
  end
end
