# frozen_string_literal: true

module Faker
  class Beer < Base
    flexible :beer

    class << self
      ##
      # Produces a random beer name.
      #
      # @return [String]
      #
      # @example
      #   Faker::Beer.name #=> "Pliny The Elder"
      #
      # @faker.version 1.6.2
      def name
        fetch('beer.name')
      end

      ##
      # Produces a random beer style.
      #
      # @return [String]
      #
      # @example
      #   Faker::Beer.style #=> "Wood-aged Beer"
      #
      # @faker.version 1.6.2
      def style
        fetch('beer.style')
      end

      ##
      # Produces a random beer hops.
      #
      # @return [String]
      #
      # @example
      #   Faker::Beer.hop #=> "Sterling"
      #
      # @faker.version 1.6.2
      def hop
        fetch('beer.hop')
      end

      ##
      # Produces a random beer yeast.
      #
      # @return [String]
      #
      # @example
      #   Faker::Beer.yeast #=> "5335 - Lactobacillus"
      #
      # @faker.version 1.6.2
      def yeast
        fetch('beer.yeast')
      end

      ##
      # Produces a random beer malt.
      #
      # @return [String]
      #
      # @example
      #   Faker::Beer.malts #=> "Munich"
      #
      # @faker.version 1.6.2
      def malts
        fetch('beer.malt')
      end

      ##
      # Produces a random beer IBU.
      #
      # @return [String]
      #
      # @example
      #   Faker::Beer.ibu #=> "87 IBU"
      #
      # @faker.version 1.6.2
      def ibu
        "#{rand(10..100)} IBU"
      end

      ##
      # Produces a random beer alcohol percentage.
      #
      # @return [String]
      #
      # @example
      #   Faker::Beer.alcohol #=> "5.4%"
      #
      # @faker.version 1.6.2
      def alcohol
        "#{rand(2.0..10.0).round(1)}%"
      end

      ##
      # Produces a random beer blg level.
      #
      # @return [String]
      #
      # @example
      #   Faker::Beer.blg #=> "5.1Blg"
      #
      # @faker.version 1.6.2
      def blg
        "#{rand(5.0..20.0).round(1)}°Blg"
      end
    end
  end
end
