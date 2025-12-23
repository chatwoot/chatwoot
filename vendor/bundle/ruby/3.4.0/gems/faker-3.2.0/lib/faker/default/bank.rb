# frozen_string_literal: true

module Faker
  class Bank < Base
    flexible :bank

    class << self
      ##
      # Produces a bank account number.
      #
      # @param digits [Integer] Number of digits that the generated account number should have.
      # @return [String]
      #
      # @example
      #   Faker::Bank.account_number #=> 6738582379
      #   Faker::Bank.account_number(digits: 13) #=> 673858237902
      #
      # @faker.version 1.9.1
      def account_number(digits: 10)
        output = ''

        output += rand.to_s[2..] while output.length < digits

        output[0...digits]
      end

      ##
      # Produces a bank iban number.
      #
      # @param country_code [String, nil] Specifies what country prefix is used to generate the iban code. Providing `nil` will use a random country.
      # @return [String]
      #
      # @example
      #   Faker::Bank.iban #=> "GB76DZJM33188515981979"
      #   Faker::Bank.iban(country_code: "be") #=> "BE6375388567752043"
      #   Faker::Bank.iban(country_code: nil) #=> "DE45186738071857270067"
      #
      # @faker.version 1.7.0
      def iban(country_code: 'GB')
        # Each country has its own format for bank accounts
        # Many of them use letters in certain parts of the account
        # Using regex patterns we can create virtually any type of bank account
        country_code ||= iban_country_code

        begin
          pattern = fetch("bank.iban_details.#{country_code.downcase}.bban_pattern")
        rescue I18n::MissingTranslationData
          raise ArgumentError, "Could not find iban details for #{country_code}"
        end

        # Use Faker::Base.regexify for creating a sample from bank account format regex
        account = Base.regexify(/#{pattern}/)

        # Add country code and checksum to the generated account to form valid IBAN
        country_code.upcase + iban_checksum(country_code, account) + account
      end

      ##
      # Produces the ISO 3166 code of a country that uses the IBAN system.
      #
      # @return [String]
      #
      # @example
      #   Faker::Bank.iban_country_code #=> "CH"
      #
      # @faker.version next
      def iban_country_code
        sample(translate('faker.bank.iban_details').keys).to_s.upcase
      end

      ##
      # Produces a bank name.
      #
      # @return [String]
      #
      # @example
      #   Faker::Bank.name #=> "ABN AMRO CORPORATE FINANCE LIMITED"
      #
      # @faker.version 1.7.0
      def name
        fetch('bank.name')
      end

      ##
      # Produces a routing number.
      #
      # @return [String]
      #
      # @example
      #   Faker::Bank.routing_number #=> "729343831"
      #
      # @faker.version 1.9.1
      def routing_number
        valid_routing_number
      end

      ##
      # Produces a valid routing number.
      #
      # @return [String]
      #
      # @example
      #   Faker::Bank.routing_number #=> "729343831"
      #
      # @faker.version 1.9.1
      def routing_number_with_format
        compile_fraction(valid_routing_number)
      end

      ##
      # Produces a swift / bic number.
      #
      # @return [String]
      #
      # @example
      #   Faker::Bank.swift_bic #=> "AAFMGB21"
      #
      # @faker.version 1.7.0
      def swift_bic
        fetch('bank.swift_bic')
      end

      ##
      # Produces an Australian BSB (Bank-State-Branch) number
      #
      # @return [String]
      #
      # @example
      #   Faker::Bank.bsb_number
      #     #=> "036616"
      #
      # @faker.version 2.13.0
      def bsb_number
        compile_bsb_number
      end

      private

      def checksum(num_string)
        num_array = num_string.chars.map(&:to_i)
        (
          7 * (num_array[0] + num_array[3] + num_array[6]) +
            3 * (num_array[1] + num_array[4] + num_array[7]) +
            9 * (num_array[2] + num_array[5])
        ) % 10
      end

      def compile_routing_number
        digit_one_two = %w[00 01 02 03 04 05 06 07 08 09 10 11 12]
        ((21..32).to_a + (61..72).to_a + [80]).each { |x| digit_one_two << x.to_s }
        digit_one_two.sample + rand_numstring + rand_numstring + rand_numstring + rand_numstring + rand_numstring + rand_numstring + rand_numstring
      end

      def compile_bsb_number
        digit_one_two = %w[01 03 06 08 11 12 73 76 78 30]
        state = (2..7).to_a.map(&:to_s).sample
        digit_one_two.sample + state + rand_numstring + rand_numstring + rand_numstring
      end

      # Calculates the mandatory checksum in 3rd and 4th characters in IBAN format
      # source: https://en.wikipedia.org/wiki/International_Bank_Account_Number#Generating_IBAN_check_digits
      def iban_checksum(country_code, account)
        # Converts letters to numbers according the iban rules, A=10..Z=35
        account_to_number = "#{account}#{country_code}00".upcase.chars.map do |d|
          d =~ /[A-Z]/ ? (d.ord - 55).to_s : d
        end.join.to_i

        # This is the correct answer to (iban_to_num + checksum) % 97 == 1
        checksum = 98 - (account_to_number % 97)

        # Use leftpad to make the size always to 2
        checksum.to_s.rjust(2, '0')
      end

      def valid_routing_number
        routing_number = compile_routing_number
        checksum = checksum(routing_number)
        return routing_number if valid_checksum?(routing_number, checksum)

        routing_number[0..7] + checksum.to_s
      end

      def valid_checksum?(routing_number, checksum)
        routing_number[8].to_i == checksum
      end

      def compile_fraction(routing_num)
        prefix = (1..50).to_a.map(&:to_s).sample
        numerator = routing_num.chars[5..8].join.to_i.to_s
        denominator = routing_num.chars[0..4].join.to_i.to_s
        "#{prefix}-#{numerator}/#{denominator}"
      end

      def rand_numstring
        (0..9).to_a.map(&:to_s).sample
      end
    end
  end
end
