# frozen_string_literal: true

module Faker
  class Kpop < Base
    class << self
      ##
      # Produces the name of a 1990's 'OG' K-Pop group.
      #
      # @return [String]
      #
      # @example
      #   Faker::Kpop.i_groups #=> "Seo Taiji and Boys"
      #
      # @faker.version 1.8.5
      def i_groups
        fetch('kpop.i_groups')
      end

      ##
      # Produces the name of a 2000's K-Pop group.
      #
      # @return [String]
      #
      # @example
      #   Faker::Kpop.ii_groups #=> "Girls' Generation"
      #
      # @faker.version 1.8.5
      def ii_groups
        fetch('kpop.ii_groups')
      end

      ##
      # Produces the name of a 2010's K-Pop group.
      #
      # @return [String]
      #
      # @example
      #   Faker::Kpop.iii_groups #=> "Trouble Maker"
      #
      # @faker.version 1.8.5
      def iii_groups
        fetch('kpop.iii_groups')
      end

      ##
      # Produces the name of a K-Pop girl group.
      #
      # @return [String]
      #
      # @example
      #   Faker::Kpop.girl_groups #=> "2NE1"
      #
      # @faker.version 1.8.5
      def girl_groups
        fetch('kpop.girl_groups')
      end

      ##
      # Produces the name of a K-Pop boy band.
      #
      # @return [String]
      #
      # @example
      #   Faker::Kpop.boy_bands #=> "Exo"
      #
      # @faker.version 1.8.5
      def boy_bands
        fetch('kpop.boy_bands')
      end

      ##
      # Produces the name of a solo K-Pop artist.
      #
      # @return [String]
      #
      # @example
      #   Faker::Kpop.solo #=> "T.O.P"
      #
      # @faker.version 1.8.5
      def solo
        fetch('kpop.solo')
      end
    end
  end
end
