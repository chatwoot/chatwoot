# frozen_string_literal: true

module Faker
  class Barcode < Base
    class << self
      ##
      # Returns a EAN 8 or 13 digit format barcode number with check digit
      #  @return [String]
      #
      #  @example
      #     Faker::Barcode.ean      => "85657526"
      #     Faker::Barcode.ean(8)   => "30152700"
      #     Faker::Barcode.ean(13)  => "2115190480285"
      #
      # @faker.version 2.14.0
      def ean(length = 8)
        generate_barcode("barcode.ean_#{Integer(length)}")
      end

      ##
      # Returns a EAN 8 or 13 digit format barcode number with composite string attached with check digit
      #  @return [String]
      #
      #  @example
      #     Faker::Barcode.ean_with_composite_sumbology      => "41007624|JHOC6649"
      #     Faker::Barcode.ean_with_composite_sumbology(8)   => "38357961|XUYJ3266"
      #     Faker::Barcode.ean_with_composite_sumbology(13)  => "9530722443911|CKHWQHID"
      #
      # @faker.version 2.14.0
      def ean_with_composite_symbology(length = 8)
        "#{ean(length)}|#{bothify(parse('barcode.composite_symbol'))}"
      end

      ##
      # Returns a UPC_A format barcode number with check digit
      #  @return [String]
      #
      #  @example
      #     Faker::Barcode.upc_a      => "766807541831"
      #
      # @faker.version 2.14.0
      def upc_a
        generate_barcode('barcode.upc_a')
      end

      ##
      # Returns a UPC_E format barcode number with check digit
      #  @return [String]
      #
      #  @example
      #     Faker::Barcode.upc_e      => "03746820"
      #
      # @faker.version 2.14.0
      def upc_e
        generate_barcode('barcode.upc_e')
      end

      ##
      # Returns a UPC_A format barcode number with composite string attached with check digit
      #  @return [String]
      #
      #  @example
      #     Faker::Barcode.upc_a_with_composite_symbology      => "790670155765|JOVG6208"
      #
      # @faker.version 2.14.0
      def upc_a_with_composite_symbology
        "#{upc_a}|#{bothify(parse('barcode.composite_symbol'))}"
      end

      ##
      # Returns a UPC_E format barcode number with composite string attached with check digit
      #  @return [String]
      #
      #  @example
      #     Faker::Barcode.upc_e_with_composite_symbology      => "05149247|BKZX9722"
      #
      # @faker.version 2.14.0
      def upc_e_with_composite_symbology
        "#{upc_e}|#{bothify(parse('barcode.composite_symbol'))}"
      end

      ##
      # Returns a ISBN format barcode number with check digit
      #  @return [String]
      #
      #  @example
      #     Faker::Barcode.isbn      => "9798363807732"
      #
      # @faker.version 2.14.0
      def isbn
        generate_barcode('barcode.isbn')
      end

      ##
      # Returns a ISMN format barcode number with check digit
      #  @return [String]
      #
      #  @example
      #     Faker::Barcode.ismn      => "9790527672897"
      #
      # @faker.version 2.14.0
      def ismn
        generate_barcode('barcode.ismn')
      end

      ##
      # Returns a ISSN format barcode number with check digit
      #  @return [String]
      #
      #  @example
      #     Faker::Barcode.issn      => "9775541703338"
      #
      # @faker.version 2.14.0
      def issn
        generate_barcode('barcode.issn')
      end

      private

      def generate_barcode(key)
        barcode = parse(key)
        check_digit = generate_check_digit(*sum_even_odd(barcode))
        "#{barcode}#{check_digit}"
      end

      ##
      # Returns the sum of even and odd numbers from value passed
      #
      # @return [Array]
      #
      # @example
      #   Faker::Barcode.send(:sum_even_odd, 12345)   => [9, 5]
      #   Faker::Barcode.send(:sum_even_odd, 87465)   => [17, 13]
      #
      # @faker.version 2.14.0
      def sum_even_odd(fake_num)
        number = fake_num.to_i
        sum_even, sum_odd = 0, 0, index = 1

        while number != 0
          index.even? ? sum_even += number % 10 : sum_odd += number % 10

          number /= 10
          index += 1
        end

        [sum_odd, sum_even]
      end

      ##
      # Generates the check digits from sum passed
      #
      # @return [Integer]
      #
      # @example
      #   Faker::Barcode.send(:generate_check_digit, 12, 4)   => 0
      #   Faker::Barcode.send(:generate_check_digit, 23, 5)   => 6
      #
      # @faker.version 2.14.0
      def generate_check_digit(odd_sum, even_sum)
        (10 - (odd_sum * 3 + even_sum) % 10) % 10
      end
    end
  end
end
