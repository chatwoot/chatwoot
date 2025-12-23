# frozen_string_literal: true

module Faker
  class Appliance < Base
    class << self
      ##
      # Produces the name of an appliance brand.
      #
      # @return [String]
      #
      # @example
      #   Faker::Appliance.brand #=> "Bosch"
      #
      # @faker.version 1.9.0
      def brand
        fetch('appliance.brand')
      end

      ##
      # Produces the name of a type of appliance equipment.
      #
      # @return [String]
      #
      # @example
      #   Faker::Appliance.equipment #=> "Appliance plug"
      #
      # @faker.version 1.9.0
      def equipment
        fetch('appliance.equipment')
      end
    end
  end
end
