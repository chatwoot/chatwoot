# frozen_string_literal: true

module Faker
  class Coffee < Base
    flexible :coffee

    class << self
      ##
      # Produces a random blend name.
      #
      # @return [String]
      #
      # @example
      #   Faker::Coffee.blend_name #=> "Major Java"
      #
      # @faker.version 1.9.0
      def blend_name
        parse('coffee.blend_name')
      end

      ##
      # Produces a random coffee origin place.
      #
      # @return [String]
      #
      # @example
      #   Faker::Coffee.origin #=> "Oaxaca, Mexico"
      #
      # @faker.version 1.9.0
      def origin
        country = fetch('coffee.country')
        region = fetch("coffee.regions.#{search_format(country)}")
        "#{region}, #{country}"
      end

      ##
      # Produces a random coffee variety.
      #
      # @return [String]
      #
      # @example
      #   Faker::Coffee.variety #=> "Red Bourbon"
      #
      # @faker.version 1.9.0
      def variety
        fetch('coffee.variety')
      end

      ##
      # Produces a string containing a random description of a coffee's taste.
      #
      # @return [String]
      #
      # @example
      #   Faker::Coffee.notes #=> "dull, tea-like, cantaloupe, soy sauce, marshmallow"
      #
      # @faker.version 1.9.0
      def notes
        parse('coffee.notes')
      end

      ##
      # Produces a random coffee taste intensity.
      #
      # @return [String]
      #
      # @example
      #   Faker::Coffee.intensifier #=> "mild"
      #
      # @faker.version 1.9.0
      def intensifier
        fetch('coffee.intensifier')
      end

      private

      def search_format(key)
        key.split.length > 1 ? key.split.join('_').downcase : key.downcase
      end
    end
  end
end
