# frozen_string_literal: true

module Faker
  class Space < Base
    flexible :space

    class << self
      ##
      # Produces the name of a planet.
      #
      # @return [String]
      #
      # @example
      #   Faker::Space.planet #=> "Venus"
      #
      # @faker.version 1.6.4
      def planet
        fetch('space.planet')
      end

      ##
      # Produces the name of a moon.
      #
      # @return [String]
      #
      # @example
      #   Faker::Space.moon #=> "Europa"
      #
      # @faker.version 1.6.4
      def moon
        fetch('space.moon')
      end

      ##
      # Produces the name of a galaxy.
      #
      # @return [String]
      #
      # @example
      #   Faker::Space.galaxy #=> "Andromeda"
      #
      # @faker.version 1.6.4
      def galaxy
        fetch('space.galaxy')
      end

      ##
      # Produces the name of a nebula.
      #
      # @return [String]
      #
      # @example
      #   Faker::Space.nebula #=> "Triffid Nebula"
      #
      # @faker.version 1.6.4
      def nebula
        fetch('space.nebula')
      end

      ##
      # Produces the name of a star cluster.
      #
      # @return [String]
      #
      # @example
      #   Faker::Space.star_cluster #=> "Messier 70"
      #
      # @faker.version 1.6.4
      def star_cluster
        fetch('space.star_cluster')
      end

      ##
      # Produces the name of a constellation.
      #
      # @return [String]
      #
      # @example
      #   Faker::Space.constellation #=> "Orion"
      #
      # @faker.version 1.6.4
      def constellation
        fetch('space.constellation')
      end

      ##
      # Produces the name of a star.
      #
      # @return [String]
      #
      # @example
      #   Faker::Space.star #=> "Proxima Centauri"
      #
      # @faker.version 1.6.4
      def star
        fetch('space.star')
      end

      ##
      # Produces the name of a space agency.
      #
      # @return [String]
      #
      # @example
      #   Faker::Space.agency #=> "Japan Aerospace Exploration Agency"
      #
      # @faker.version 1.6.4
      def agency
        fetch('space.agency')
      end

      ##
      # Produces a space agency abbreviation.
      #
      # @return [String]
      #
      # @example
      #   Faker::Space.agency_abv #=> "NASA"
      #
      # @faker.version 1.6.4
      def agency_abv
        fetch('space.agency_abv')
      end

      ##
      # Produces the name of a NASA spacecraft.
      #
      # @return [String]
      #
      # @example
      #   Faker::Space.nasa_space_craft #=> "Endeavour"
      #
      # @faker.version 1.6.4
      def nasa_space_craft
        fetch('space.nasa_space_craft')
      end

      ##
      # Produces the name of a space company.
      #
      # @return [String]
      #
      # @example
      #   Faker::Space.company #=> "SpaceX"
      #
      # @faker.version 1.6.4
      def company
        fetch('space.company')
      end

      ##
      # Produces a distance measurement.
      #
      # @return [String]
      #
      # @example
      #   Faker::Space.distance_measurement #=> "15 parsecs"
      #
      # @faker.version 1.6.4
      def distance_measurement
        "#{rand(10..100)} #{fetch('space.distance_measurement')}"
      end

      ##
      # Produces the name of a meteorite.
      #
      # @return [String]
      #
      # @example
      #   Faker::Space.meteorite #=> "Ensisheim"
      #
      # @faker.version 1.7.0
      def meteorite
        fetch('space.meteorite')
      end

      ##
      # Produces the name of a launch vehicle.
      #
      # @return [String]
      #
      # @example
      #   Faker::Space.launch_vehicle #=> "Saturn IV"
      #
      # @faker.version 1.9.0
      def launch_vehicle
        fetch('space.launch_vehicle')
      end
    end
  end
end
