# frozen_string_literal: true

module Faker
  class NationalHealthService < Base
    class << self
      ##
      # Produces a random British NHS number.
      #
      # @return [String]
      #
      # @example
      #   Faker::NationalHealthService.british_number #=> "403 958 5577"
      #
      # @faker.version 1.9.2
      def british_number
        base_number = rand(400_000_001...499_999_999)
        # If the check digit is equivalent to 10, the number is invalid.
        # See https://en.wikipedia.org/wiki/NHS_number
        base_number -= 1 if check_digit(number: base_number) == 10
        "#{base_number}#{check_digit(number: base_number)}".to_s
                                                           .chars
                                                           .insert(3, ' ')
                                                           .insert(7, ' ')
                                                           .join
      end

      ##
      # Produces a random British NHS number's check digit.
      #
      # @param number [Integer] Specifies the NHS number the check digit belongs to.
      # @return [Integer]
      #
      # @example
      #   Faker::NationalHealthService.check_digit(number: 400_012_114) #=> 6
      #
      # @faker.version 1.9.2
      def check_digit(number: 0)
        sum = 0
        number.to_s.chars.each_with_index do |digit, idx|
          position = idx + 1
          sum += (digit.to_i * (11 - position))
        end
        result = 11 - (sum % 11)

        # A value of 11 is considered the same as 0
        # See https://en.wikipedia.org/wiki/NHS_number
        return 0 if result == 11

        result
      end
    end
  end
end
