# frozen_string_literal: true

module Faker
  class Military < Base
    class << self
      ##
      # Produces a rank in the U.S. Army.
      #
      # @return [String]
      #
      # @example
      #   Faker::Military.army_rank #=> "Staff Sergeant"
      #
      # @faker.version 1.9.0
      def army_rank
        fetch('military.army_rank')
      end

      ##
      # Produces a rank in the U.S. Marines.
      #
      # @return [String]
      #
      # @example
      #   Faker::Military.marines_rank #=> "Gunnery Sergeant"
      #
      # @faker.version 1.9.0
      def marines_rank
        fetch('military.marines_rank')
      end

      ##
      # Produces a rank in the U.S. Navy.
      #
      # @return [String]
      #
      # @example
      #   Faker::Military.navy_rank #=> "Seaman"
      #
      # @faker.version 1.9.0
      def navy_rank
        fetch('military.navy_rank')
      end

      ##
      # Produces a rank in the U.S. Air Force.
      #
      # @return [String]
      #
      # @example
      #   Faker::Military.air_force_rank #=> "Captain"
      #
      # @faker.version 1.9.0
      def air_force_rank
        fetch('military.air_force_rank')
      end

      ##
      # Produces a rank in the U.S. Space Force.
      #
      # @return [String]
      #
      # @example
      #   Faker::Military.space_force_rank #=> "Senior Enlisted Advisor of the Space Force"
      #
      # @faker.version next
      def space_force_rank
        fetch('military.space_force_rank')
      end

      ##
      # Produces a rank in the U.S. Coast Guard
      #
      # @return [String]
      #
      # @example
      #   Faker::Military.coast_guard_rank #=> "Master Chief Petty Officer of the Coast Guard"
      #
      # @faker.version next
      def coast_guard_rank
        fetch('military.coast_guard_rank')
      end

      ##
      # Produces a U.S. Department of Defense Paygrade.
      #
      # @return [String]
      #
      # @example
      #   Faker::Military.dod_paygrade #=> "E-6"
      #
      # @faker.version 1.9.0
      def dod_paygrade
        fetch('military.dod_paygrade')
      end
    end
  end
end
