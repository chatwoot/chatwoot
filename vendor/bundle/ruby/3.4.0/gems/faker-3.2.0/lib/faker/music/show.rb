# frozen_string_literal: true

module Faker
  class Show < Base
    class << self
      ##
      # Produces the name of a musical for an older audience
      #
      # @return [String]
      #
      # @example
      #   Faker::Alphanumeric.alpha
      #     #=> "West Side Story"
      #
      # @faker.version 2.13.0
      def adult_musical
        fetch('show.adult_musical')
      end

      ##
      # Produces the name of a musical for a younger audience
      #
      # @return [String]
      #
      # @example
      #   Faker::Alphanumeric.alpha
      #     #=> "Into the Woods JR."
      #
      # @faker.version 2.13.0
      def kids_musical
        fetch('show.kids_musical')
      end

      ##
      # Produces the name of a play
      #
      # @return [String]
      #
      # @example
      #   Faker::Alphanumeric.alpha
      #     #=> "Death of a Salesman"
      #
      # @faker.version 2.13.0
      def play
        fetch('show.play')
      end
    end
  end
end
