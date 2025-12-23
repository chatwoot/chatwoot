# frozen_string_literal: true

module Faker
  class PhoneNumber < Base
    class << self
      ##
      # Produces a random phone number in a random format (may or may not have a country code, extension and can have different dividers).
      #
      # @return [String]
      #
      # @example
      #   Faker::PhoneNumber.phone_number #=> "397.693.1309 x4321"
      #
      # @faker.version 0.3.0
      def phone_number
        parse('phone_number.formats')
      end

      ##
      # Produces a random cell phone number in a random format (may or may not have a country code and can have different dividers).
      #
      # @return [String]
      #
      # @example
      #   Faker::PhoneNumber.cell_phone #=> "(186)285-7925"
      #
      # @faker.version 1.0.0
      def cell_phone
        parse('cell_phone.formats')
      end

      ##
      # Produces a random country code.
      #
      # @return [String]
      #
      # @example
      #   Faker::PhoneNumber.country_code #=> "+20"
      #
      # @faker.version 1.9.2
      def country_code
        "+#{fetch('country_code')}"
      end

      ##
      # Produces a random phone number with country code.
      #
      # @return [String]
      #
      # @example
      #   Faker::PhoneNumber.phone_number_with_country_code #=> "+95 1-672-173-8153"
      #
      # @faker.version 1.9.2
      def phone_number_with_country_code
        "#{country_code} #{phone_number}"
      end

      ##
      # Produces a random cell phone number with country code.
      #
      # @return [String]
      #
      # @example
      #   Faker::PhoneNumber.cell_phone_with_country_code #=> "+974 (190) 987-9034"
      #
      # @faker.version 1.9.2
      def cell_phone_with_country_code
        "#{country_code} #{cell_phone}"
      end

      ##
      # Produces a random phone number in e164 format.
      #
      # @return [String]
      #
      # @example
      #   Faker::PhoneNumber.cell_phone_in_e164 #=> "+944937040625"
      #
      # @faker.version 1.9.2
      def cell_phone_in_e164
        cell_phone_with_country_code.delete('^+0-9')
      end

      ##
      # Produces a random US or Canada-based area code.
      #
      # @return [String]
      #
      # @example
      #   Faker::PhoneNumber.area_code #=> "201"
      #
      # @faker.version 1.3.0
      def area_code
        fetch('phone_number.area_code')
      rescue I18n::MissingTranslationData
        nil
      end

      ##
      # Produces a random US or Canada-based exchange code.
      #
      # @return [String]
      #
      # @example
      #   Faker::PhoneNumber.exchange_code #=> "208"
      #
      # @faker.version 1.3.0
      def exchange_code
        fetch('phone_number.exchange_code')
      rescue I18n::MissingTranslationData
        nil
      end

      ##
      # Produces a random US or Canada-based extension / subscriber number. Can be used for both extensions and last four digits of phone number.
      #
      # @param length [Integer] Specifies the length of the return value.
      # @return [String]
      #
      # @example
      #   Faker::PhoneNumber.subscriber_number #=> "3873"
      #   Faker::PhoneNumber.subscriber_number(length: 2) #=> "39"
      #   Faker::PhoneNumber.extension #=> "3764"
      #
      # @faker.version 1.3.0
      def subscriber_number(length: 4)
        rand.to_s[2..(1 + length)]
      end

      alias extension subscriber_number
    end
  end
end
