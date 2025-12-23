# frozen_string_literal: true

module Faker
  # Port of http://shinytoylabs.com/jargon/
  # Are you having trouble writing tech-savvy dialogue for your latest screenplay?
  # Worry not! Hollywood-grade technical talk is ready to fill out any form where you need to look smart.
  class Hacker < Base
    flexible :hacker

    class << self
      ##
      # Produces something smart.
      #
      # @return [String]
      #
      # @example
      #   Faker::Hacker.say_something_smart
      #     #=> "Try to compress the SQL interface, maybe it will program the back-end hard drive!"
      #
      # @faker.version 1.4.0
      def say_something_smart
        sample(phrases)
      end

      ##
      # Short technical abbreviations.
      #
      # @return [String]
      #
      # @example
      #   Faker::Hacker.abbreviation #=> "RAM"
      #
      # @faker.version 1.4.0
      def abbreviation
        fetch('hacker.abbreviation')
      end

      ##
      # Hacker-centric adjectives.
      #
      # @return [String]
      #
      # @example
      #   Faker::Hacker.adjective #=> "open-source"
      #
      # @faker.version 1.4.0
      def adjective
        fetch('hacker.adjective')
      end

      ##
      # Only the best hacker-related nouns.
      #
      # @return [String]
      #
      # @example
      #   Faker::Hacker.noun #=> "bandwidth"
      #
      # @faker.version 1.4.0
      def noun
        fetch('hacker.noun')
      end

      ##
      # Actions that hackers take.
      #
      # @return [String]
      #
      # @example
      #   Faker::Hacker.verb #=> "bypass"
      #
      # @faker.version 1.4.0
      def verb
        fetch('hacker.verb')
      end

      ##
      # Produces a verb that ends with '-ing'.
      #
      # @return [String]
      #
      # @example
      #   Faker::Hacker.ingverb #=> "synthesizing"
      #
      # @faker.version 1.4.0
      def ingverb
        fetch('hacker.ingverb')
      end

      # @private
      def phrases
        ["If we #{verb} the #{noun}, we can get to the #{abbreviation} #{noun} through the #{adjective} #{abbreviation} #{noun}!",
         "We need to #{verb} the #{adjective} #{abbreviation} #{noun}!",
         "Try to #{verb} the #{abbreviation} #{noun}, maybe it will #{verb} the #{adjective} #{noun}!",
         "You can't #{verb} the #{noun} without #{ingverb} the #{adjective} #{abbreviation} #{noun}!",
         "Use the #{adjective} #{abbreviation} #{noun}, then you can #{verb} the #{adjective} #{noun}!",
         "The #{abbreviation} #{noun} is down, #{verb} the #{adjective} #{noun} so we can #{verb} the #{abbreviation} #{noun}!",
         "#{ingverb} the #{noun} won't do anything, we need to #{verb} the #{adjective} #{abbreviation} #{noun}!".capitalize,
         "I'll #{verb} the #{adjective} #{abbreviation} #{noun}, that should #{noun} the #{abbreviation} #{noun}!"]
      end
    end
  end
end
