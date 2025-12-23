# frozen_string_literal: true

module Faker
  class Fantasy
    class Tolkien < Base
      flexible :tolkien

      class << self
        ##
        # Produces a character from Tolkien's legendarium
        #
        # @return [String]
        #
        # @example
        #   Faker::Fantasy::Tolkien.character
        #    #=> "Goldberry"
        #
        # @faker.version next
        def character
          fetch('tolkien.characters')
        end

        ##
        # Produces a location from Tolkien's legendarium
        #
        # @return [String]
        #
        # @example
        #   Faker::Fantasy::Tolkien.location
        #    #=> "Helm's Deep"
        #
        # @faker.version next
        def location
          fetch('tolkien.locations')
        end

        ##
        # Produces a race from Tolkien's legendarium
        #
        # @return [String]
        #
        # @example
        #   Faker::Fantasy::Tolkien.race
        #     #=> "Uruk-hai"
        #
        # @faker.version next
        def race
          fetch('tolkien.races')
        end

        ##
        # Produces the name of a poem from Tolkien's legendarium
        #
        # @return [String]
        #
        # @example
        #   Faker::Fantasy::Tolkien.poem
        #     #=> "Chip the glasses and crack the plates"
        #
        # @faker.version next
        def poem
          fetch('tolkien.poems')
        end
      end
    end
  end
end
