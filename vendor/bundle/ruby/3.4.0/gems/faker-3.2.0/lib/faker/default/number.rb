# frozen_string_literal: true

module Faker
  class Number < Base
    class << self
      ##
      # Produce a random number.
      #
      # @param digits [Integer] Number of digits that the generated number should have.
      # @return [Integer]
      #
      # @example
      #   Faker::Number.number(digits: 10) #=> 1968353479
      #
      # @faker.version 1.0.0
      def number(digits: 10)
        return if digits < 1
        return rand(0..9).round if digits == 1

        # Ensure the first digit is not zero
        ([non_zero_digit] + generate(digits - 1)).join.to_i
      end

      ##
      # Produce a random number with a leading zero.
      #
      # @param digits [Integer] Number of digits that the generated number should have.
      # @return [String]
      #
      # @example
      #   Faker::Number.leading_zero_number(digits: 10) #=> "0669336915"
      #
      # @faker.version 1.0.0
      def leading_zero_number(digits: 10)
        "0#{(2..digits).collect { digit }.join}"
      end

      ##
      # Produce a number with a number of digits, preserves leading zeroes.
      #
      # @param digits [Integer] Number of digits that the generated number should have.
      # @return [String]
      #
      # @example
      #   Faker::Number.decimal_part(digits: 2) #=> "09"
      #
      # @faker.version 1.0.0
      def decimal_part(digits: 10)
        num = ''
        if digits > 1
          num = non_zero_digit
          digits -= 1
        end
        leading_zero_number(digits: digits) + num.to_s
      end

      ##
      # Produces a float.
      #
      # @param l_digits [Integer] Number of digits that the generated decimal should have to the left of the decimal point.
      # @param r_digits [Integer] Number of digits that the generated decimal should have to the right of the decimal point.
      # @return [Float]
      #
      # @example
      #   Faker::Number.decimal(l_digits: 2) #=> 11.88
      #   Faker::Number.decimal(l_digits: 3, r_digits: 3) #=> 181.843
      #
      # @faker.version 1.0.0
      def decimal(l_digits: 5, r_digits: 2)
        l_d = number(digits: l_digits)

        # Ensure the last digit is not zero
        # so it does not get truncated on converting to float
        r_d = generate(r_digits - 1).join + non_zero_digit.to_s

        "#{l_d}.#{r_d}".to_f
      end

      ##
      # Produces a non-zero single-digit integer.
      #
      # @return [Integer]
      #
      # @example
      #   Faker::Number.non_zero_digit #=> 8
      #
      # @faker.version 1.0.0
      def non_zero_digit
        rand(1..9)
      end

      ##
      # Produces a single-digit integer.
      #
      # @return [Integer]
      #
      # @example
      #   Faker::Number.digit #=> 1
      #
      # @faker.version 1.0.0
      def digit
        rand(10)
      end

      ##
      # Produces a number in hexadecimal format.
      #
      # @param digits [Integer] Number of digits in the he
      # @return [String]
      #
      # @example
      #   Faker::Number.hexadecimal(digits: 3) #=> "e74"
      #
      # @faker.version 1.0.0
      def hexadecimal(digits: 6)
        hex = ''
        digits.times { hex += rand(15).to_s(16) }
        hex
      end

      # Produces a number in binary format.
      #
      # @param digits [Integer] Number of digits to generate the binary as string
      # @return [String]
      #
      # @example
      #   Faker::Number.binary(digits: 4) #=> "1001"
      #
      # @faker.version next
      def binary(digits: 4)
        bin = ''
        digits.times { bin += rand(2).to_s(2) }
        bin
      end

      ##
      # Produces a float given a mean and standard deviation.
      #
      # @param mean [Integer]
      # @param standard_deviation [Numeric]
      # @return [Float]
      #
      # @example
      #   Faker::Number.normal(mean: 50, standard_deviation: 3.5) #=> 47.14669604069156
      #
      # @faker.version 1.0.0
      def normal(mean: 1, standard_deviation: 1)
        theta = 2 * Math::PI * rand
        rho = Math.sqrt(-2 * Math.log(1 - rand))
        scale = standard_deviation * rho
        mean + scale * Math.cos(theta)
      end

      ##
      # Produces a number between two provided values. Boundaries are inclusive.
      #
      # @param from [Numeric] The lowest number to include.
      # @param to [Numeric] The highest number to include.
      # @return [Numeric]
      #
      # @example
      #   Faker::Number.between(from: 1, to: 10) #=> 7
      #   Faker::Number.between(from: 0.0, to: 1.0) #=> 0.7844640543957383
      #
      # @faker.version 1.0.0
      def between(from: 1.00, to: 5000.00)
        Faker::Base.rand_in_range(from, to)
      end

      ##
      # Produces a number within two provided values. Boundaries are inclusive or exclusive depending on the range passed.
      #
      # @param range [Range] The range from which to generate a number.
      # @return [Numeric]
      #
      # @example
      #   Faker::Number.within(range: 1..10) #=> 7
      #   Faker::Number.within(range: 0.0..1.0) #=> 0.7844640543957383
      #
      # @faker.version 1.0.0
      def within(range: 1.00..5000.00)
        between(from: range.min, to: range.max)
      end

      ##
      # Produces a positive float.
      #
      # @param from [Integer] The lower boundary.
      # @param to [Integer] The higher boundary.
      # @return [Float]
      #
      # @example
      #   Faker::Number.positive #=> 235.59238499107653
      #
      # @faker.version 1.0.0
      def positive(from: 1.00, to: 5000.00)
        random_number = between(from: from, to: to)

        greater_than_zero(random_number)
      end

      ##
      # Produces a negative float.
      #
      # @param from [Integer] The lower boundary.
      # @param to [Integer] The higher boundary.
      # @return [Float]
      #
      # @example
      #   Faker::Number.negative #=> -4480.042585669558
      #
      # @faker.version 1.0.0
      def negative(from: -5000.00, to: -1.00)
        random_number = between(from: from, to: to)

        less_than_zero(random_number)
      end

      private

      def generate(count)
        return [] if count.zero?

        Array.new(count) { digit }
      end

      def greater_than_zero(number)
        should_be(number, :>)
      end

      def less_than_zero(number)
        should_be(number, :<)
      end

      def should_be(number, method_to_compare)
        if number.send(method_to_compare, 0)
          number
        else
          number * -1
        end
      end
    end
  end
end
