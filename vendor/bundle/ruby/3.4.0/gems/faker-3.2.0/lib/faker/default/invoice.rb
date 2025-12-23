# frozen_string_literal: true

module Faker
  class Invoice < Base
    flexible :invoice

    class << self
      ##
      # Produces a random amount between values with 2 decimals
      #
      # @param from [Integer] Specifies lower limit.
      # @param to [Integer] Specifies upper limit.
      # @return [Integer]
      #
      # @example
      #   Faker::Finance.amount_between #=> 0
      #   Faker::Finance.amount_between(0, 10) #=> 4.33
      #
      # @faker.version 1.9.0
      def amount_between(from: 0, to: 0)
        Faker::Base.rand_in_range(from, to).round(2)
      end

      ##
      # Produces a random valid reference accoring to the International bank slip reference https://en.wikipedia.org/wiki/Creditor_Reference
      #
      # @param ref [String] Specifies reference base.
      # @return [String]
      #
      # @example
      #   Faker::Invoice.creditor_reference #=> "RF34118592570724925498"
      #
      # @faker.version 1.9.0
      def creditor_reference(ref: '')
        ref = reference if ref.empty?

        "RF#{iban_checksum('RF', ref)}#{ref}"
      end

      ##
      # Produces a random valid reference.
      #
      # @param ref [String] Specifies reference base.
      # @return [String]
      #
      # @example
      #   Faker::Invoice.reference #=> "45656646957845"
      #
      # @faker.version 1.9.0
      def reference(ref: '')
        pattern = fetch('invoice.reference.pattern')

        ref = Base.regexify(/#{pattern}/) if ref.empty?

        # If reference contains reserved '#' characters we need to calculate check_digits as well
        check_digit_match = ref.match(/#+/)
        if check_digit_match
          # Get the method for selected language
          check_digit_method = fetch('invoice.reference.check_digit_method')

          # Calculate the check digit with matching method name
          # Trim all '#' from the reference before calculating that
          check_digit = send(check_digit_method, ref.tr('#', ''))

          # Make sure that our check digit is as long as all of the '###' we found
          check_digit = check_digit.to_s.rjust(check_digit_match[0].length, '0')

          # Replace all of the
          ref = ref.sub(check_digit_match[0], check_digit)
        end

        ref
      end

      private

      # Calculates the mandatory checksum in 3rd and 4th characters in IBAN format
      # source: https://en.wikipedia.org/wiki/International_Bank_Account_Number#Validating_the_IBAN
      def iban_checksum(country_code, account)
        # Converts letters to numbers according the iban rules, A=10..Z=35
        account_to_number = "#{account}#{country_code}00".upcase.chars.map do |d|
          d =~ /[A-Z]/ ? (d.ord - 55).to_s : d
        end.join.to_i

        # This is answer to (iban_to_num + checksum) % 97 == 1
        checksum = (1 - account_to_number) % 97

        # Use leftpad to make the size always to 2
        checksum.to_s.rjust(2, '0')
      end

      # 731 Method
      # Source: https://wiki.xmldation.com/support/fk/finnish_reference_number
      def method_731(base)
        weighted_sum = calculate_weighted_sum(base, [7, 3, 1])
        mod10_remainder(weighted_sum)
      end

      # Norsk Modulus 10 - KIDMOD10
      def kidmod10(base)
        weighted_sum = calculate_weighted_sum(base, [1, 2])
        mod10_remainder(weighted_sum)
      end

      # Calculates weighted sum
      #
      # For example with 12345678, [1,2]
      # Ref.num. 1 2 3 4 5 6 7 8
      # Multipl. 1 2 1 2 1 2 1 2
      # Total 1+ 4+ 3+ 8+ 5+1+2+ 7+1+6 = 38
      def calculate_weighted_sum(base, weight_factors)
        base.to_s.reverse.each_char.with_index.map do |digit, index|
          digit.to_i * weight_factors.at(index % weight_factors.length)
        end.reduce(:+) # reduce(:+) = sum() but with better ruby version support
      end

      # MOD-10 - remainder
      def mod10_remainder(number)
        -number % 10
      end
    end
  end
end
