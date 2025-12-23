# frozen_string_literal: true

module Faker
  class Emotion < Base
    class << self
      ##
      # Produces an emotion noun.
      #
      # @return [String]
      #
      # @example
      #   Faker::Emotion.noun #=> "amazement"
      #
      # @faker.version next
      def noun
        fetch('emotion.noun')
      end

      ##
      # Produces an emotion adjective.
      #
      # @return [String]
      #
      # @example
      #   Faker::Emotion.adjective # => "nonplussed"
      #
      # @faker.version next
      def adjective
        fetch('emotion.adjective')
      end
    end
  end
end
