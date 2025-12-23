# frozen_string_literal: true

module Faker
  class Device < Base
    class << self
      ##
      # Produces a build number between 1 and 500.
      #
      # @return [Integer]
      #
      # @example
      #   Faker::Device.build_number #=> 5
      #
      # @faker.version 1.9.0
      def build_number
        Faker::Number.between(from: 1, to: 500)
      end

      ##
      # Produces the name of a manufacturer for a device.
      #
      # @return [String]
      #
      # @example
      #   Faker::Device.manufacturer #=> "Apple"
      #
      # @faker.version 1.9.0
      def manufacturer
        fetch('device.manufacturer')
      end

      ##
      # Produces a model name for a device.
      #
      # @return [String]
      #
      # @example
      #   Faker::Device.model_name #=> "iPhone 4"
      #
      # @faker.version 1.9.0
      def model_name
        fetch('device.model_name')
      end

      ##
      # Produces the name of a platform for a device.
      #
      # @return [String]
      #
      # @example
      #   Faker::Device.platform #=> "webOS"
      #
      # @faker.version 1.9.0
      def platform
        fetch('device.platform')
      end

      ##
      # Produces a serial code for a device.
      #
      # @return [String]
      #
      # @example
      #   Faker::Device.serial #=> "ejfjnRNInxh0363JC2WM"
      #
      # @faker.version 1.9.0
      def serial
        fetch('device.serial')
      end

      ##
      # Produces a version number between 1 and 1000.
      #
      # @return [Integer]
      #
      # @example
      #   Faker::Device.version #=> 42
      #
      # @faker.version 1.9.0
      def version
        Faker::Number.between(from: 1, to: 1000)
      end
    end
  end
end
