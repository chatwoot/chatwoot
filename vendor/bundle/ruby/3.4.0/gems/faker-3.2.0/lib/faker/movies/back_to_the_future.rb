# frozen_string_literal: true

module Faker
  class Movies
    class BackToTheFuture < Base
      class << self
        ##
        # Produces a character from Back to the Future.
        #
        # @return [String]
        #
        # @example
        #   Faker::Movies::BackToTheFuture.character #=> "Marty McFly"
        #
        # @faker.version 1.8.5
        def character
          fetch('back_to_the_future.characters')
        end

        ##
        # Produces a date from Back to the Future.
        #
        # @return [String]
        #
        # @example
        #   Faker::Movies::BackToTheFuture.date #=> "November 5, 1955"
        #
        # @faker.version 1.8.5
        def date
          fetch('back_to_the_future.dates')
        end

        ##
        # Produces a quote from Back to the Future.
        #
        # @return [String]
        #
        # @example
        #   Faker::Movies::BackToTheFuture.quote
        #     #=> "Roads? Where we're going, we don't need roads."
        #
        # @faker.version 1.8.5
        def quote
          fetch('back_to_the_future.quotes')
        end
      end
    end
  end
end
