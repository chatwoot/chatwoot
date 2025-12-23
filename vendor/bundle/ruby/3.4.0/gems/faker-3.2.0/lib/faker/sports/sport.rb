# frozen_string_literal: true

module Faker
  class Sport < Base
    class << self
      ##
      # Produces a sport from the modern olympics or paralympics, summer or winter.
      #
      # @param include_ancient [Boolean] If true, may produce a sport from the ancient olympics
      # @param include_unusual [Boolean] If true, may produce an unusual (definitely not olympic) sport
      #
      # @return [String]
      #
      # @example
      #   Faker::Sport.sport #=> "Football"
      # @example
      #   Faker::Sport.sport(include_ancient: true) #=> "Chariot racing"
      # @example
      #   Faker::Sport.sport(include_unsual: true) #=> "Flugtag/Birdman"
      # @example
      #   Faker::Sport.sport(include_ancient:true, include_unusual: true) #=> "Water polo"
      #
      # @faker.version next
      def sport(include_ancient: false, include_unusual: false)
        sports = []
        sports.concat(
          fetch_all('sport.summer_olympics'),
          fetch_all('sport.summer_paralympics'),
          fetch_all('sport.winter_olympics'),
          fetch_all('sport.winter_paralympics')
        )
        sports.concat(fetch_all('sport.ancient_olympics')) if include_ancient
        sports.concat(fetch_all('sport.unusual')) if include_unusual
        sample(sports)
      end

      ##
      # Produces a sport from the summer olympics.
      #
      # @return [String]
      #
      # @example
      #   Faker::Sport.summer_olympics_sport #=> "Archery"
      #
      # @faker.version next
      def summer_olympics_sport
        fetch('sport.summer_olympics')
      end

      ##
      # Produces a sport from the winter olympics.
      #
      # @return [String]
      #
      # @example
      #   Faker::Sport.winter_olympics_sport #=> "Bobsleigh"
      #
      # @faker.version next
      def winter_olympics_sport
        fetch('sport.winter_olympics')
      end

      ##
      # Produces a sport from the summer paralympics.
      #
      # @return [String]
      #
      # @example
      #   Faker::Sport.summer_paralympics_sport #=> "Wheelchair Basketball"
      #
      # @faker.version next
      def summer_paralympics_sport
        fetch('sport.summer_paralympics')
      end

      ##
      # Produces a sport from the winter paralympics.
      #
      # @return [String]
      #
      # @example
      #   Faker::Sport.winter_paralympics_sport #=> "Para Ice Hockey"
      #
      # @faker.version next
      def winter_paralympics_sport
        fetch('sport.winter_paralympics')
      end

      ##
      # Produces an unusual sport.
      #
      # @return [String]
      #
      # @example
      #   Faker::Sport.unusual_sport #=> "Camel Jumping"
      #
      # @faker.version next
      def unusual_sport
        fetch('sport.unusual')
      end

      ##
      # Produces a sport from the ancient olympics.
      #
      # @return [String]
      #
      # @example
      #   Faker::Sport.ancient_olympics_sport #=> "Pankration"
      #
      # @faker.version next
      def ancient_olympics_sport
        fetch('sport.ancient_olympics')
      end
    end
  end
end
