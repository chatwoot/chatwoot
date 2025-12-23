# frozen_string_literal: true

module Faker
  class TvShows
    class MichaelScott < Base
      class << self
        ##
        # Produces a quote from Michael Scott.
        #
        # @return [String]
        #
        # @example
        #   Faker::TvShows::MichaelScott.quote
        #     #=> "I am Beyoncé, always."
        #
        # @faker.version 1.9.0
        def quote
          fetch('michael_scott.quotes')
        end
      end
    end
  end
end
