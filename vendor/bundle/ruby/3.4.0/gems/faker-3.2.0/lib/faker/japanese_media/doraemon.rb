# frozen_string_literal: true

module Faker
  class JapaneseMedia
    class Doraemon < Base
      class << self
        ##
        # Produces a character from Doraemon.
        #
        # @return [String]
        #
        # @example
        #   Faker::JapaneseMedia::Doraemon.character #=> "Nobita"
        #
        # @faker.version next
        def character
          fetch('doraemon.characters')
        end

        ##
        # Produces a gadget from Doraemon.
        #
        # @return [String]
        #
        # @example
        #   Faker::JapaneseMedia::Doraemon.gadget #=> "Anywhere Door"
        #
        # @faker.version next
        def gadget
          fetch('doraemon.gadgets')
        end

        ##
        # Produces a location from Doraemon.
        #
        # @return [String]
        #
        # @example
        #   Faker::JapaneseMedia::Doraemon.location #=> "Tokyo"
        #
        # @faker.version next
        def location
          fetch('doraemon.locations')
        end
      end
    end
  end
end
