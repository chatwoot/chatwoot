# frozen_string_literal: true

module Faker
  class Drone < Base
    class << self
      ##
      # Returns random drone name with company
      #
      # @return [string]
      #
      # @example
      #   Faker::Drone.name #=> "DJI Mavic Air 2"
      #
      # @faker.version 2.14.0
      def name
        fetch('drone.name')
      end

      ##
      # Returns total drone weight in grams
      #
      # @return [String]
      #
      # @example
      #   Faker::Drone.weight #=> "570 g"
      #
      # @faker.version 2.14.0
      def weight
        parse('drone.weight')
      end

      ##
      # Returns maximum ascent speed for drone in m/s
      #
      # @return [String]
      #
      # @example
      #   Faker::Drone.max_ascent_speed #=> "4 m/s"
      #
      # @faker.version 2.14.0
      def max_ascent_speed
        parse('drone.max_ascent_speed')
      end

      ##
      # Returns maximum descent speed for drone in m/s
      #
      # @return [String]
      #
      # @example
      #   Faker::Drone.max_descent_speed #=> "4 m/s"
      #
      # @faker.version 2.14.0
      def max_descent_speed
        parse('drone.max_descent_speed')
      end

      ##
      # Returns max flight time for drone in optimal conditions
      #
      # @return [String]
      #
      # @example
      #   Faker::Drone.flight_time #=> "34 min"
      #
      # @faker.version 2.14.0
      def flight_time
        parse('drone.flight_time')
      end

      ##
      # Returns max altitude drone can go above sea level in meters
      #
      # @return [String]
      #
      # @example
      #   Faker::Drone.max_altitude #=> "5000 m"
      #
      # @faker.version 2.14.0
      def max_altitude
        parse('drone.max_altitude')
      end

      ##
      # Returns how far drone can go in optimal condition when full charged in meters
      #
      # @return [String]
      #
      # @example
      #   Faker::Drone.max_flight_distance #=> "18500 m"
      #
      # @faker.version 2.14.0
      def max_flight_distance
        parse('drone.max_flight_distance')
      end

      ##
      # Returns max horizontal speed by drone in m/s
      #
      # @return [String]
      #
      # @example
      #   Faker::Drone.max_speed #=> "19 m/s"
      #
      # @faker.version 2.14.0
      def max_speed
        parse('drone.max_speed')
      end

      ##
      # Returns max wind resistance by drone in m/s
      #
      # @return [String]
      #
      # @example
      #   Faker::Drone.max_wind_resistance #=> "10.5 m/s"
      #
      # @faker.version 2.14.0
      def max_wind_resistance
        parse('drone.max_wind_resistance')
      end

      ##
      # Returns max angular velocity of drone in degrees/s
      #
      # @return [String]
      #
      # @example
      #   Faker::Drone.max_angular_velocity #=> "250 degree/s"
      #
      # @faker.version 2.14.0
      def max_angular_velocity
        parse('drone.max_angular_velocity')
      end

      ##
      # Returns max tilt angle drone can go in degrees
      #
      # @return [String]
      #
      # @example
      #   Faker::Drone.max_tilt_angle #=> "35 degrees"
      #
      # @faker.version 2.14.0
      def max_tilt_angle
        parse('drone.max_tilt_angle')
      end

      ##
      # Returns operating temperature for drone in Fahrenheit
      #
      # @return [String]
      #
      # @example
      #   Faker::Drone.operating_temperature #=> "14-104F"
      #
      # @faker.version 2.14.0
      def operating_temperature
        parse('drone.operating_temperature')
      end

      ##
      # Returns the drone battery capacity
      #
      # @return [String]
      #
      # @example
      #   Faker::Drone.battery_capacity #=> "3500 mAh"
      #
      # @faker.version 2.14.0
      def battery_capacity
        parse('drone.battery_capacity')
      end

      ##
      # Returns battery voltage
      #
      # @return [String]
      #
      # @example
      #   Faker::Drone.battery_voltage #=> "13.2V"
      #
      # @faker.version 2.14.0
      def battery_voltage
        parse('drone.battery_voltage')
      end

      ##
      # Returns the battery type
      #
      # @return [String]
      #
      # @example
      #   Faker::Drone.battery_type #=> "LiPo 4S"
      #
      # @faker.version 2.14.0
      def battery_type
        parse('drone.battery_type')
      end

      ##
      # Returns total battery weight in grams
      #
      # @return [String]
      #
      # @example
      #   Faker::Drone.battery_weight #=> "198 g"
      #
      # @faker.version 2.14.0
      def battery_weight
        parse('drone.battery_weight')
      end

      ##
      # Returns charging temperature for battery in Fahrenheit
      #
      # @return [String]
      #
      # @example
      #   Faker::Drone.charging_temperature #=> "41-104F"
      #
      # @faker.version 2.14.0
      def charging_temperature
        parse('drone.charging_temperature')
      end

      ##
      # Returns max chargin power required for battery
      #
      # @return [String]
      #
      # @example
      #   Faker::Drone.max_charging_power #=> "38W"
      #
      # @faker.version 2.14.0
      def max_charging_power
        parse('drone.max_charging_power')
      end

      ##
      # Returns camera ISO range for drone
      #
      # @return [String]
      #
      # @example
      #   Faker::Drone.iso #=> "100-3200"
      #
      # @faker.version 2.14.0
      def iso
        parse('drone.iso')
      end

      ##
      # Returns max camera resolution in MP"
      #
      # @return [String]
      #
      # @example
      #   Faker::Drone.max_resolution #=> "48MP"
      #
      # @faker.version 2.14.0
      def max_resolution
        parse('drone.max_resolution')
      end

      ##
      # Returns photo format for drone
      #
      # @return [String]
      #
      # @example
      #   Faker::Drone.photo_format #=> "JPEG"
      #
      # @faker.version 2.14.0
      def photo_format
        parse('drone.photo_format')
      end

      ##
      # Returns video format
      #
      # @return [String]
      #
      # @example
      #   Faker::Drone.video_format #=> "MP4"
      #
      # @faker.version 2.14.0
      def video_format
        parse('drone.video_format')
      end

      ##
      # Returns max and min shutter speed for camera
      #
      # @return [String]
      #
      # @example
      #   Faker::Drone.shutter_speed_range #=> "8-1/8000s"
      #
      # @faker.version 2.14.0
      def shutter_speed_range
        "#{fetch('drone.max_shutter_speed')}-#{fetch('drone.min_shutter_speed')}#{fetch('drone.shutter_speed_units')}"
      end

      ##
      # Returns max shutter speed for camera
      #
      # @return [String]
      #
      # @example
      #   Faker::Drone.max_shutter_speed #=> "60s"
      #
      # @faker.version 2.14.0
      def max_shutter_speed
        "#{fetch('drone.max_shutter_speed')}#{fetch('drone.shutter_speed_units')}"
      end

      ##
      # Returns min shutter speed for camera
      #
      # @return [String]
      #
      # @example
      #   Faker::Drone.min_shutter_speed #=> "1/8000s"
      #
      # @faker.version 2.14.0
      def min_shutter_speed
        "#{fetch('drone.min_shutter_speed')}#{fetch('drone.shutter_speed_units')}"
      end
    end
  end
end
