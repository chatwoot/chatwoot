# frozen_string_literal: true

module Faker
  class ChileRut < Base
    class << self
      @last_rut = nil

      ##
      # Produces a random Chilean RUT (Rol Unico Tributario, ID with 8 digits).
      #
      # @param min_rut [Integer] Specifies the minimum value of the rut.
      # @param fixed [Boolean] Determines if the rut is fixed (returns the min_rut value).
      # @return [Number]
      #
      # @example
      #   Faker::ChileRut.rut #=> 11235813
      #   Faker::ChileRut.rut(min_rut: 20890156) #=> 31853211
      #   Faker::ChileRut.rut(min_rut: 20890156, fixed: true) #=> 20890156
      #
      # @faker.version 1.9.2
      def rut(min_rut: 1, fixed: false)
        @last_rut = fixed ? min_rut : rand_in_range(min_rut, 99_999_999)
      end

      ##
      # Produces a random Chilean digito verificador (check-digit).
      #
      # @return [String]
      #
      # @example
      #   Faker::ChileRut.dv #=> "k"
      #
      # @faker.version 1.9.2
      def dv
        split_reversed_rut = @last_rut.to_s.reverse.chars
        seq = [2, 3, 4, 5, 6, 7]
        i = 0
        digit_sum = split_reversed_rut.reduce(0) do |sum, n|
          partial_result = sum.to_i + (n.to_i * seq[i])
          i = i == 5 ? 0 : i + 1
          partial_result
        end
        partial_check_digit = 11 - (digit_sum % 11)
        case partial_check_digit
        when 11
          '0'
        when 10
          'k'
        else
          partial_check_digit.to_s
        end
      end

      ##
      # Produces a random Chilean digito verificador (check-digit).
      # Alias for english speaking devs.
      #
      # @return [String]
      #
      # @example
      #   Faker::ChileRut.check_digit #=> "5"
      #
      # @faker.version 1.9.2
      def check_digit
        dv
      end

      ##
      # Produces a random Chilean RUT (Rol Unico Tributario, ID with 8 digits) with a dv (digito verificador, check-digit).
      #
      # @param min_rut [Integer] Specifies the minimum value of the rut.
      # @param fixed [Boolean] Determines if the rut is fixed (returns the min_rut value).
      # @return [String]
      #
      # @example
      #   Faker::ChileRut.full_rut #=> "30686957-4"
      #   Faker::ChileRut.full_rut(min_rut: 20890156) #=> "30686957-4"
      #   Faker::ChileRut.full_rut(min_rut: 30686957, fixed: true) #=> "30686957-4"
      #
      # @faker.version next
      def full_rut(min_rut: 0, fixed: false, formatted: false)
        if formatted
          "#{rut(min_rut: min_rut, fixed: fixed).to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1.').reverse}-#{dv}"
        else
          "#{rut(min_rut: min_rut, fixed: fixed)}-#{dv}"
        end
      end

      attr_reader :last_rut
    end
  end
end
