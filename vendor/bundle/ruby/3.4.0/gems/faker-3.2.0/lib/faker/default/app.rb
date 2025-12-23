# frozen_string_literal: true

module Faker
  class App < Base
    class << self
      ##
      # Produces an app name.
      #
      # @return [String]
      #
      # @example
      #   Faker::App.name #=> "Treeflex"
      #
      # @faker.version 1.4.3
      def name
        fetch('app.name')
      end

      ##
      # Produces a version string.
      #
      # @return [String]
      #
      # @example
      #   Faker::App.version #=> "1.85"
      #
      # @faker.version 1.4.3
      def version
        parse('app.version')
      end

      ##
      # Produces the name of an app's author.
      #
      # @return [String]
      #
      # @example
      #   Faker::App.author #=> "Daphne Swift"
      #
      # @faker.version 1.4.3
      def author
        parse('app.author')
      end

      ##
      # Produces a String representing a semantic version identifier.
      #
      # @param major [Integer, Range] An integer to use or a range to pick the integer from.
      # @param minor [Integer, Range] An integer to use or a range to pick the integer from.
      # @param patch [Integer, Range] An integer to use or a range to pick the integer from.
      # @return [String]
      #
      # @example
      #   Faker::App.semantic_version #=> "3.2.5"
      # @example
      #   Faker::App.semantic_version(major: 42) #=> "42.5.2"
      # @example
      #   Faker::App.semantic_version(minor: 100..101) #=> "42.100.4"
      # @example
      #   Faker::App.semantic_version(patch: 5..6) #=> "7.2.6"
      #
      # @faker.version 1.4.3
      def semantic_version(major: 0..9, minor: 0..9, patch: 1..9)
        [major, minor, patch].map { |chunk| sample(Array(chunk)) }.join('.')
      end
    end
  end
end
