# frozen_string_literal: true

module Faker
  module Religion
    class Bible < Base
      flexible :bible

      class << self
        ##
        # Returns a random bible character.
        #
        # @return [String]
        #
        # @example
        # Faker::Religion::Bible.character #=> "Jesus"
        #
        # @faker.version next
        def character
          fetch('bible.character')
        end

        ##
        # Returns a random location(city or town) from the bible
        #
        # @return [String]
        #
        # @example
        # Faker::Religion::Bible.location #=> "Nasareth"
        #
        # @faker.version next
        def location
          fetch('bible.location')
        end

        ##
        # Returns a random quote from the location.
        #
        # @return [String]
        #
        # @example
        # Faker::Religion::Bible.quote #=> "Seek first the kingdom of God "
        #
        # @faker.version next
        def quote
          fetch('bible.quote')
        end
      end
    end
  end
end
