# frozen_string_literal: true

module Faker
  class Job < Base
    flexible :job

    class << self
      ##
      # Produces a random job title.
      #
      # @return [String]
      #
      # @example
      #   Faker::Job.title #=> "Construction Manager"
      #
      # @faker.version 1.7.0
      def title
        parse('job.title')
      end

      ##
      # Produces a random job position.
      #
      # @return [String]
      #
      # @example
      #   Faker::Job.position #=> "Strategist"
      #
      # @faker.version 1.8.7
      def position
        fetch('job.position')
      end

      ##
      # Produces a random job field.
      #
      # @return [String]
      #
      # @example
      #   Faker::Job.field #=> "Banking"
      #
      # @faker.version 1.7.0
      def field
        fetch('job.field')
      end

      ##
      # Produces a random job skill.
      #
      # @return [String]
      #
      # @example
      #   Faker::Job.key_skill #=> "Leadership"
      #
      # @faker.version 1.7.0
      def key_skill
        fetch('job.key_skills')
      end
    end
  end
end
