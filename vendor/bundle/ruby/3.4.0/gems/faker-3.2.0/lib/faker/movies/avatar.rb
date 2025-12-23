# frozen_string_literal: true

module Faker
  class Movies
    class Avatar < Base
      class << self
        ##
        # Produces a character from Avatar.
        #
        # @return [String]
        #
        # @example
        #   Faker::Movies::Avatar.character #=> "Jake Sully"
        #
        # @faker.version next
        def character
          fetch('avatar.characters')
        end

        ##
        # Produces a date from Avatar.
        #
        # @return [String]
        #
        # @example
        #   Faker::Movies::Avatar.date #=> "December 15, 2022"
        #
        # @faker.version next
        def date
          fetch('avatar.dates')
        end

        ##
        # Produces a quote from Avatar.
        #
        # @return [String]
        #
        # @example
        #   Faker::Movies::Avatar.quote
        #     #=> "If it ain't raining, we ain't training."
        #
        # @faker.version next
        def quote
          fetch('avatar.quotes')
        end
      end
    end
  end
end
