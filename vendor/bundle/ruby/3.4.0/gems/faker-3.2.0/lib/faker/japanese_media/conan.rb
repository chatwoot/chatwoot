# frozen_string_literal: true

module Faker
  class JapaneseMedia
    class Conan < Base
      class << self
        ##
        # Produces a character from Conan.
        #
        # @return [String]
        #
        # @example
        #   Faker::JapaneseMedia::Conan.character #=> "Conan Edogawa"
        #
        # @faker.version next
        def character
          fetch('conan.characters')
        end

        ##
        # Produces a gadget from Conan.
        #
        # @return [String]
        #
        # @example
        #   Faker::JapaneseMedia::Conan.gadget #=> "Voice-Changing Bowtie"
        #
        # @faker.version next
        def gadget
          fetch('conan.gadgets')
        end

        ##
        # Produces a vehicle from Conan.
        #
        # @return [String]
        #
        # @example
        #   Faker::JapaneseMedia::Conan.vehicle #=> "Agasa's Volkswagen Beetle"
        #
        # @faker.version next
        def vehicle
          fetch('conan.vehicles')
        end
      end
    end
  end
end
