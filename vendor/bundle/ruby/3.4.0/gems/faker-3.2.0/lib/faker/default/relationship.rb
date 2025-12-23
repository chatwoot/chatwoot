# frozen_string_literal: true

module Faker
  class Relationship < Base
    flexible :relationship

    class << self
      ##
      # Produces a random family relationship.
      #
      # @return [String]
      #
      # @example
      #   Faker::Relationship.familial #=> "Grandfather"
      #
      # @faker.version 1.9.2
      def familial(connection: nil)
        familial_connections = translate('faker.relationship.familial').keys

        if connection.nil?
          connection = sample(familial_connections).to_s
        else
          connection = connection.to_s.downcase

          unless familial_connections.include?(connection.to_sym)
            raise ArgumentError,
                  "Familial connections can be left blank or #{familial_connections.join(', ')}"
          end
        end

        fetch("relationship.familial.#{connection}")
      end

      ##
      # Produces a random in-law relationship.
      #
      # @return [String]
      #
      # @example
      #   Faker::Relationship.in_law #=> "Brother-in-law"
      #
      # @faker.version 1.9.2
      def in_law
        fetch('relationship.in_law')
      end

      ##
      # Produces a random spouse relationship.
      #
      # @return [String]
      #
      # @example
      #   Faker::Relationship.spouse #=> "Husband"
      #
      # @faker.version 1.9.2
      def spouse
        fetch('relationship.spouse')
      end

      ##
      # Produces a random parent relationship.
      #
      # @return [String]
      #
      # @example
      #   Faker::Relationship.parent #=> "Father"
      #
      # @faker.version 1.9.2
      def parent
        fetch('relationship.parent')
      end

      ##
      # Produces a random sibling relationship.
      #
      # @return [String]
      #
      # @example
      #   Faker::Relationship.sibling #=> "Sister"
      #
      # @faker.version 1.9.2
      def sibling
        fetch('relationship.sibling')
      end
    end
  end
end
