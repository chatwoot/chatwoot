# frozen_string_literal: true

module Faker
  class SlackEmoji < Base
    class << self
      ##
      # Produces a random slack emoji from people category.
      #
      # @return [String]
      #
      # @example
      #   Faker::SlackEmoji.people #=> ":sleepy:"
      #
      # @faker.version 1.5.0
      def people
        fetch('slack_emoji.people')
      end

      ##
      # Produces a random slack emoji from nature category.
      #
      # @return [String]
      #
      # @example
      #   Faker::SlackEmoji.nature #=> ":mount_fuji:"
      #
      # @faker.version 1.5.0
      def nature
        fetch('slack_emoji.nature')
      end

      ##
      # Produces a random slack emoji from food and drink category.
      #
      # @return [String]
      #
      # @example
      #   Faker::SlackEmoji.food_and_drink #=> ":beers:"
      #
      # @faker.version 1.5.0
      def food_and_drink
        fetch('slack_emoji.food_and_drink')
      end

      ##
      # Produces a random slack emoji from celebration category.
      #
      # @return [String]
      #
      # @example
      #   Faker::SlackEmoji.celebration #=> ":tada:"
      #
      # @faker.version 1.5.0
      def celebration
        fetch('slack_emoji.celebration')
      end

      ##
      # Produces a random slack emoji from activity category.
      #
      # @return [String]
      #
      # @example
      #   Faker::SlackEmoji.activity #=> ":soccer:"
      #
      # @faker.version 1.5.0
      def activity
        fetch('slack_emoji.activity')
      end

      ##
      # Produces a random slack emoji from travel and places category.
      #
      # @return [String]
      #
      # @example
      #   Faker::SlackEmoji.travel_and_places #=> ":metro:"
      #
      # @faker.version 1.5.0
      def travel_and_places
        fetch('slack_emoji.travel_and_places')
      end

      ##
      # Produces a random slack emoji from objects and symbols category.
      #
      # @return [String]
      #
      # @example
      #   Faker::SlackEmoji.objects_and_symbols #=> ":id:"
      #
      # @faker.version 1.5.0
      def objects_and_symbols
        fetch('slack_emoji.objects_and_symbols')
      end

      ##
      # Produces a random slack emoji from custom category.
      #
      # @return [String]
      #
      # @example
      #   Faker::SlackEmoji.custom #=> ":slack:"
      #
      # @faker.version 1.5.0
      def custom
        fetch('slack_emoji.custom')
      end

      ##
      # Produces a random slack emoji from any category.
      #
      # @return [String]
      #
      # @example
      #   Faker::SlackEmoji.emoji #=> ":pizza:"
      #
      # @faker.version 1.5.0
      def emoji
        parse('slack_emoji.emoji')
      end
    end
  end
end
