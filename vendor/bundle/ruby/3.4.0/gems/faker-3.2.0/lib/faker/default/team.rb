# frozen_string_literal: true

module Faker
  class Team < Base
    flexible :team

    class << self
      ##
      # Produces a team name from a state and a creature.
      #
      # @return [String]
      #
      # @example
      #   Faker::Team.name #=> "Oregon vixens"
      #
      # @faker.version 1.3.0
      def name
        parse('team.name')
      end

      ##
      # Produces a team creature.
      #
      # @return [String]
      #
      # @example
      #   Faker::Team.creature #=> "geese"
      #
      # @faker.version 1.3.0
      def creature
        fetch('team.creature')
      end

      ##
      # Produces a team state.
      #
      # @return [String]
      #
      # @example
      #   Faker::Team.state #=> "Oregon"
      #
      # @faker.version 1.3.0
      def state
        fetch('address.state')
      end

      ##
      # Produces a team sport.
      #
      # @return [String]
      #
      # @example
      #   Faker::Team.sport #=> "Lacrosse"
      #
      # @faker.version 1.5.0
      def sport
        fetch('team.sport')
      end

      ##
      # Produces the name of a team mascot.
      #
      # @return [String]
      #
      # @example
      #   Faker::Team.mascot #=> "Hugo"
      #
      # @faker.version 1.8.1
      def mascot
        fetch('team.mascot')
      end
    end
  end
end
