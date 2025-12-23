# frozen_string_literal: true

module Faker
  class Blood < Base
    flexible :blood

    class << self
      ##
      # Produces a random blood type.
      #
      # @return [String]
      #
      # @example
      #   Faker::Blood.type #=> "AB"
      #
      # @faker.version 2.13.0
      def type
        fetch('blood.type')
      end

      ##
      # Produces a random blood RH-Factor.
      #
      # @return [String]
      #
      # @example
      #   Faker::Blood.rh_factor #=> "-"
      #
      # @faker.version 2.13.0
      def rh_factor
        fetch('blood.rh_factor')
      end

      ##
      # Produces a random blood group name.
      #
      # @return [String]
      #
      # @example
      #   Faker::Blood.group #=> "AB-"
      #
      # @faker.version 2.13.0
      def group
        parse('blood.group')
      end
    end
  end
end
