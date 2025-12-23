# frozen_string_literal: true

module Faker
  class Game < Base
    flexible :game

    class << self
      ##
      # Produces the name of a video game.
      #
      # @return [String]
      #
      # @example
      #   Faker::Game.title #=> "Half-Life 2"
      #
      # @faker.version 1.9.4
      def title
        fetch('game.title')
      end

      ##
      # Produces the name of a video game genre.
      #
      # @return [String]
      #
      # @example
      #   Faker::Game.genre #=> "Real-time strategy"
      #
      # @faker.version 1.9.4
      def genre
        fetch('game.genre')
      end

      ##
      # Produces the name of a video game console or platform.
      #
      # @return [String]
      #
      # @example
      #   Faker::Game.platform #=> "Nintendo Switch"
      #
      # @faker.version 1.9.4
      def platform
        fetch('game.platform')
      end
    end
  end
end
