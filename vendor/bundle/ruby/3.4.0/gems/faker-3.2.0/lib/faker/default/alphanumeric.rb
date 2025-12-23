# frozen_string_literal: true

module Faker
  class Alphanumeric < Base
    ##
    # List of characters allowed for alphanumeric strings
    # @private
    ALPHANUMS = LLetters + Numbers

    class << self
      ##
      # Produces a random string of alphabetic characters (no digits)
      #
      # @param number [Integer] The length of the string to generate
      #
      # @return [String]
      #
      # @example
      #   Faker::Alphanumeric.alpha(number: 10) #=> "zlvubkrwga"
      #
      # @faker.version 1.9.2
      def alpha(number: 32)
        char_count = resolve(number)
        return '' if char_count.to_i < 1

        Array.new(char_count) { sample(self::LLetters) }.join
      end

      ##
      # Produces a random string of alphanumeric characters
      #
      # @param number [Integer] The number of characters to generate
      # @param min_alpha [Integer] The minimum number of alphabetic to add to the string
      # @param min_numeric [Integer] The minimum number of numbers to add to the string
      #
      # @return [String]
      #
      # @example
      #   Faker::Alphanumeric.alphanumeric(number: 10) #=> "3yfq2phxtb"
      # @example
      #   Faker::Alphanumeric.alphanumeric(number: 10, min_alpha: 3) #=> "3yfq2phxtb"
      # @example
      #   Faker::Alphanumeric.alphanumeric(number: 10, min_alpha: 3, min_numeric: 3) #=> "3yfq2phx8b"
      #
      # @faker.version 2.1.3
      def alphanumeric(number: 32, min_alpha: 0, min_numeric: 0)
        char_count = resolve(number)
        return '' if char_count.to_i < 1
        raise ArgumentError, 'min_alpha must be greater than or equal to 0' if min_alpha&.negative?
        raise ArgumentError, 'min_numeric must be greater than or equal to 0' if min_numeric&.negative?

        return Array.new(char_count) { sample(ALPHANUMS) }.join if min_alpha.zero? && min_numeric.zero?

        raise ArgumentError, 'min_alpha + min_numeric must be <= number' if min_alpha + min_numeric > char_count

        random_count = char_count - min_alpha - min_numeric

        alphas = Array.new(min_alpha) { sample(self::LLetters) }
        numbers = Array.new(min_numeric) { sample(self::Numbers) }
        randoms = Array.new(random_count) { sample(ALPHANUMS) }

        combined = alphas + numbers + randoms
        combined.shuffle.join
      end
    end
  end
end
