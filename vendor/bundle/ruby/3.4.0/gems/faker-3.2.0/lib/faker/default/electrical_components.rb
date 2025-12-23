# frozen_string_literal: true

module Faker
  class ElectricalComponents < Base
    flexible :electrical_components

    class << self
      ##
      # Produces an active electrical component.
      #
      # @return [String]
      #
      # @example
      #   Faker::ElectricalComponents.active #=> "Transistor"
      #
      # @faker.version 1.9.0
      def active
        fetch('electrical_components.active')
      end

      ##
      # Produces a passive electrical component.
      #
      # @return [String]
      #
      # @example
      #   Faker::ElectricalComponents.passive #=> "Resistor"
      #
      # @faker.version 1.9.0
      def passive
        fetch('electrical_components.passive')
      end

      ##
      # Produces an electromechanical electrical component.
      #
      # @return [String]
      #
      # @example
      #   Faker::ElectricalComponents.electromechanical #=> "Toggle Switch"
      #
      # @faker.version 1.9.0
      def electromechanical
        fetch('electrical_components.electromechanical')
      end
    end
  end
end
