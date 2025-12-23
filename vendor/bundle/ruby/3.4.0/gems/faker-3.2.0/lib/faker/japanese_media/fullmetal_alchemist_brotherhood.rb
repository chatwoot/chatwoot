# frozen_string_literal: true

module Faker
  class JapaneseMedia
    class FmaBrotherhood < Base
      class << self
        ##
        # Produces a character from FmaBrotherhood.
        #
        # @return [String]
        #
        # @example
        #   Faker::JapaneseMedia::FmaBrotherhood.character #=> "Edward Elric"
        #
        # @faker.version next
        def character
          fetch('fma_brotherhood.characters')
        end

        ##
        # Produces a cities from FmaBrotherhood.
        #
        # @return [String]
        #
        # @example
        #   Faker::JapaneseMedia::FmaBrotherhood.city #=> "Central City"
        #
        # @faker.version next
        def city
          fetch('fma_brotherhood.cities')
        end

        ##
        # Produces a country from FmaBrotherhood.
        #
        # @return [String]
        #
        # @example
        #   Faker::JapaneseMedia::FmaBrotherhood.country #=> "Xing"
        #
        # @faker.version next
        def country
          fetch('fma_brotherhood.countries')
        end
      end
    end
  end
end
