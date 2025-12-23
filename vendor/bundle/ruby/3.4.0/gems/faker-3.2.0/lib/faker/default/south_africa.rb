# frozen_string_literal: true

module Faker
  class SouthAfrica < Base
    class << self
      ##
      # Produces a South African ID number.
      #
      # @return [String]
      #
      # @example
      #   Faker::SouthAfrica.id_number #=> "6110311856083"
      #
      # @faker.version 1.9.2
      def id_number
        Faker::IDNumber.south_african_id_number
      end

      ##
      # Produces a valid South African ID number
      #
      # @return [String]
      #
      # @example
      #   Faker::SouthAfrica.valid_id_number #=> "6110311856083"
      #
      # @faker.version 1.9.2
      def valid_id_number
        Faker::IDNumber.valid_south_african_id_number
      end

      ##
      # Produces an invalid South African ID number
      #
      # @return [String]
      #
      # @example
      #   Faker::SouthAfrica.invalid_id_number #=> "7018356904081"
      #
      # @faker.version 1.9.2
      def invalid_id_number
        Faker::IDNumber.invalid_south_african_id_number
      end

      ##
      # Produces a South African phone number.
      #
      # @return [String]
      #
      # @example
      #   Faker::SouthAfrica.phone_number #=> "010 788 5009"
      #
      # @faker.version 1.9.2
      def phone_number
        with_locale 'en-ZA' do
          Faker::PhoneNumber.phone_number
        end
      end

      ##
      # Produces a South African cell phone number.
      #
      # @return [String]
      #
      # @example
      #   Faker::SouthAfrica.cell_phone #=> "082 946 7470"
      #
      # @faker.version 1.9.2
      def cell_phone
        with_locale 'en-ZA' do
          Faker::PhoneNumber.cell_phone
        end
      end

      ##
      # Produces a South African private company registration number.
      #
      # @return [String]
      #
      # @example
      #   Faker::SouthAfrica.pty_ltd_registration_number #=> "5301/714689/07"
      #
      # @faker.version 1.9.2
      def pty_ltd_registration_number
        Faker::Company.south_african_pty_ltd_registration_number
      end

      ##
      # Produces a South African close corporation registration number.
      #
      # @return [String]
      #
      # @example
      #   Faker::SouthAfrica.close_corporation_registration_number #=> "CK74/7585/23"
      #
      # @faker.version 1.9.2
      def close_corporation_registration_number
        Faker::Company.south_african_close_corporation_registration_number
      end

      ##
      # Produces a South African listed company registration number.
      #
      # @return [String]
      #
      # @example
      #   Faker::SouthAfrica.listed_company_registration_number #=> "7039/3135/06"
      #
      # @faker.version 1.9.2
      def listed_company_registration_number
        Faker::Company.south_african_listed_company_registration_number
      end

      ##
      # Produces a South African trust registration number.
      #
      # @return [String]
      #
      # @example
      #   Faker::SouthAfrica.trust_registration_number #=> "IT38/6489900"
      #
      # @faker.version 1.9.2
      def trust_registration_number
        Faker::Company.south_african_trust_registration_number
      end

      ##
      # Produces a South African VAT number.
      #
      # @return [String]
      #
      # @example
      #   Faker::SouthAfrica.vat_number #=> "ZA79494416181"
      #
      # @faker.version 1.9.2
      def vat_number
        Faker::Finance.vat_number(country: 'ZA')
      end
    end
  end
end
