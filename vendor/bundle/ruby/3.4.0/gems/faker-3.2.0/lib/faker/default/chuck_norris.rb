# frozen_string_literal: true

module Faker
  class ChuckNorris < Base
    flexible :chuck_norris

    class << self
      ##
      # Produces a Chuck Norris Fact.
      # Original list of facts:
      # https://github.com/jenkinsci/chucknorris-plugin/blob/master/src/main/java/hudson/plugins/chucknorris/FactGenerator.java
      #
      # @return [String]
      #
      # @example
      #   Faker::ChuckNorris.fact
      #     #=> "Chuck Norris can solve the Towers of Hanoi in one move."
      #
      # @faker.version 1.6.4
      def fact
        fetch('chuck_norris.fact')
      end
    end
  end
end
