# frozen_string_literal: true

module Faker
  class Artist < Base
    class << self
      ##
      # Produces the name of an artist.
      #
      # @return [String]
      #
      # @example
      #   Faker::Artist.name #=> "Michelangelo"
      #
      # @faker.version 1.8.8
      def name
        fetch('artist.names')
      end
    end
  end
end
