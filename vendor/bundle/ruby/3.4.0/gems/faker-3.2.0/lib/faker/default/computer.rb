# frozen_string_literal: true

module Faker
  class Computer < Base
    class << self
      ##
      # Produces the name of a computer platform.
      #
      # @return [String]
      #
      # @example
      #   Faker::Computer.platform #=> "Linux"
      #
      # @faker.version 2.12.0
      def platform
        fetch('computer.platform')
      end

      ##
      # Produces the name of a computer type.
      #
      # @return [String]
      #
      # @example
      #   Faker::Computer.type #=> "server"
      #
      # @faker.version 2.12.0
      def type
        fetch('computer.type')
      end

      ##
      # Produces the name of a computer os.
      #
      # @param platform [String] optionally specify the platform `linux`, `macos`, or `windows`.
      # @return [String]
      #
      # @example
      #   Faker::Computer.os #=> "RHEL 6.10"
      #
      # @faker.version 2.12.0
      def os(platform: self.platform)
        platform = self.platform unless fetch_all('computer.platform').include?(platform)
        fetch("computer.os.#{platform.downcase}")
      end

      ##
      # Produces a string with computer platform and os
      #
      # @return [String]
      #
      # @example
      #   Faker::Computer.stack #=> "Linux, RHEL 6.10"
      #
      # @faker.version 2.12.0
      def stack
        platform = self.platform
        os = fetch("computer.os.#{platform.downcase}")
        "#{platform}, #{os}"
      end
    end
  end
end
