# frozen_string_literal: true

module Faker
  class Verb < Base
    class << self
      ##
      # Produces the base form of a random verb.
      #
      # @return [String]
      #
      # @example
      #   Faker::Verb.base #=> "hurt"
      #
      # @faker.version 1.9.0
      def base
        fetch('verbs.base')
      end

      ##
      # Produces a random verb in past tense.
      #
      # @return [String]
      #
      # @example
      #   Faker::Verb.past #=> "completed"
      #
      # @faker.version 1.9.0
      def past
        fetch('verbs.past')
      end

      ##
      # Produces a random verb in past participle.
      #
      # @return [String]
      #
      # @example
      #   Faker::Verb.past_participle #=> "digested"
      #
      # @faker.version 1.9.0
      def past_participle
        fetch('verbs.past_participle')
      end

      ##
      # Produces a random verb in simple present.
      #
      # @return [String]
      #
      # @example
      #   Faker::Verb.simple_present #=> "climbs"
      #
      # @faker.version 1.9.0
      def simple_present
        fetch('verbs.simple_present')
      end

      ##
      # Produces a random verb in the .ing form.
      #
      # @return [String]
      #
      # @example
      #   Faker::Verb.ing_form #=> "causing"
      #
      # @faker.version 1.9.0
      def ing_form
        fetch('verbs.ing_form')
      end
    end
  end
end
