# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  module Terminal
    class LocationUpdateParams < ::Stripe::RequestParams
      class Address < ::Stripe::RequestParams
        # City, district, suburb, town, or village.
        attr_accessor :city
        # Two-letter country code ([ISO 3166-1 alpha-2](https://en.wikipedia.org/wiki/ISO_3166-1_alpha-2)).
        attr_accessor :country
        # Address line 1, such as the street, PO Box, or company name.
        attr_accessor :line1
        # Address line 2, such as the apartment, suite, unit, or building.
        attr_accessor :line2
        # ZIP or postal code.
        attr_accessor :postal_code
        # State, county, province, or region.
        attr_accessor :state

        def initialize(
          city: nil,
          country: nil,
          line1: nil,
          line2: nil,
          postal_code: nil,
          state: nil
        )
          @city = city
          @country = country
          @line1 = line1
          @line2 = line2
          @postal_code = postal_code
          @state = state
        end
      end

      class AddressKana < ::Stripe::RequestParams
        # City or ward.
        attr_accessor :city
        # Two-letter country code ([ISO 3166-1 alpha-2](https://en.wikipedia.org/wiki/ISO_3166-1_alpha-2)).
        attr_accessor :country
        # Block or building number.
        attr_accessor :line1
        # Building details.
        attr_accessor :line2
        # Postal code.
        attr_accessor :postal_code
        # Prefecture.
        attr_accessor :state
        # Town or cho-me.
        attr_accessor :town

        def initialize(
          city: nil,
          country: nil,
          line1: nil,
          line2: nil,
          postal_code: nil,
          state: nil,
          town: nil
        )
          @city = city
          @country = country
          @line1 = line1
          @line2 = line2
          @postal_code = postal_code
          @state = state
          @town = town
        end
      end

      class AddressKanji < ::Stripe::RequestParams
        # City or ward.
        attr_accessor :city
        # Two-letter country code ([ISO 3166-1 alpha-2](https://en.wikipedia.org/wiki/ISO_3166-1_alpha-2)).
        attr_accessor :country
        # Block or building number.
        attr_accessor :line1
        # Building details.
        attr_accessor :line2
        # Postal code.
        attr_accessor :postal_code
        # Prefecture.
        attr_accessor :state
        # Town or cho-me.
        attr_accessor :town

        def initialize(
          city: nil,
          country: nil,
          line1: nil,
          line2: nil,
          postal_code: nil,
          state: nil,
          town: nil
        )
          @city = city
          @country = country
          @line1 = line1
          @line2 = line2
          @postal_code = postal_code
          @state = state
          @town = town
        end
      end
      # The full address of the location. You can't change the location's `country`. If you need to modify the `country` field, create a new `Location` object and re-register any existing readers to that location.
      attr_accessor :address
      # The Kana variation of the full address of the location (Japan only).
      attr_accessor :address_kana
      # The Kanji variation of the full address of the location (Japan only).
      attr_accessor :address_kanji
      # The ID of a configuration that will be used to customize all readers in this location.
      attr_accessor :configuration_overrides
      # A name for the location.
      attr_accessor :display_name
      # The Kana variation of the name for the location (Japan only).
      attr_accessor :display_name_kana
      # The Kanji variation of the name for the location (Japan only).
      attr_accessor :display_name_kanji
      # Specifies which fields in the response should be expanded.
      attr_accessor :expand
      # Set of [key-value pairs](https://stripe.com/docs/api/metadata) that you can attach to an object. This can be useful for storing additional information about the object in a structured format. Individual keys can be unset by posting an empty value to them. All keys can be unset by posting an empty value to `metadata`.
      attr_accessor :metadata
      # The phone number for the location.
      attr_accessor :phone

      def initialize(
        address: nil,
        address_kana: nil,
        address_kanji: nil,
        configuration_overrides: nil,
        display_name: nil,
        display_name_kana: nil,
        display_name_kanji: nil,
        expand: nil,
        metadata: nil,
        phone: nil
      )
        @address = address
        @address_kana = address_kana
        @address_kanji = address_kanji
        @configuration_overrides = configuration_overrides
        @display_name = display_name
        @display_name_kana = display_name_kana
        @display_name_kanji = display_name_kanji
        @expand = expand
        @metadata = metadata
        @phone = phone
      end
    end
  end
end
