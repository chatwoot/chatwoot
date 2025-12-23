# frozen_string_literal: true

module Faker
  class Esport < Base
    class << self
      ##
      # Produces the name of a professional eSports player.
      #
      # @return [String]
      #
      # @example
      #   Faker::Esport.player #=> "Crimsix"
      #
      # @faker.version 1.7.0
      def player
        fetch('esport.players')
      end

      ##
      # Produces the name of an eSports team.
      #
      # @return [String]
      #
      # @example
      #   Faker::Esport.team #=> "CLG"
      #
      # @faker.version 1.7.0
      def team
        fetch('esport.teams')
      end

      ##
      # Produces the name of an eSports league.
      #
      # @return [String]
      #
      # @example
      #   Faker::Esport.league #=> "IEM"
      #
      # @faker.version 1.7.0
      def league
        fetch('esport.leagues')
      end

      ##
      # Produces the name of an eSports event.
      #
      # @return [String]
      #
      # @example
      #   Faker::Esport.event #=> "ESL Cologne"
      #
      # @faker.version 1.7.0
      def event
        fetch('esport.events')
      end

      ##
      # Produces the name of a game played as an eSport.
      #
      # @return [String]
      #
      # @example
      #   Faker::Esport.game #=> "Dota 2"
      #
      # @faker.version 1.7.0
      def game
        fetch('esport.games')
      end
    end
  end
end
