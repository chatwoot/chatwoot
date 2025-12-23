# frozen_string_literal: true

module Faker
  class Mountain < Base
    class << self
      ##
      # Produces a name of a mountain
      #
      # @return [String]
      #
      # @example
      #   Faker::Mountain.name #=> "Mount Everest"
      #
      #  @faker.version next
      def name
        fetch('mountain.name')
      end

      ##
      # Produces a name of a range
      #
      # @return [String]
      #
      # @example
      #   Faker::Mountain.range #=> "Dhaulagiri Himalaya"
      #
      # @faker.version next
      def range
        fetch('mountain.range')
      end
    end
  end
end
