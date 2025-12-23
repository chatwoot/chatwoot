# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  class CustomerPaymentSourceUpdateParams < ::Stripe::RequestParams
    class Owner < ::Stripe::RequestParams
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
      # Owner's address.
      attr_accessor :address
      # Owner's email address.
      attr_accessor :email
      # Owner's full name.
      attr_accessor :name
      # Owner's phone number.
      attr_accessor :phone

      def initialize(address: nil, email: nil, name: nil, phone: nil)
        @address = address
        @email = email
        @name = name
        @phone = phone
      end
    end
    # The name of the person or business that owns the bank account.
    attr_accessor :account_holder_name
    # The type of entity that holds the account. This can be either `individual` or `company`.
    attr_accessor :account_holder_type
    # City/District/Suburb/Town/Village.
    attr_accessor :address_city
    # Billing address country, if provided when creating card.
    attr_accessor :address_country
    # Address line 1 (Street address/PO Box/Company name).
    attr_accessor :address_line1
    # Address line 2 (Apartment/Suite/Unit/Building).
    attr_accessor :address_line2
    # State/County/Province/Region.
    attr_accessor :address_state
    # ZIP or postal code.
    attr_accessor :address_zip
    # Two digit number representing the card’s expiration month.
    attr_accessor :exp_month
    # Four digit number representing the card’s expiration year.
    attr_accessor :exp_year
    # Specifies which fields in the response should be expanded.
    attr_accessor :expand
    # Set of [key-value pairs](https://stripe.com/docs/api/metadata) that you can attach to an object. This can be useful for storing additional information about the object in a structured format. Individual keys can be unset by posting an empty value to them. All keys can be unset by posting an empty value to `metadata`.
    attr_accessor :metadata
    # Cardholder name.
    attr_accessor :name
    # Attribute for param field owner
    attr_accessor :owner

    def initialize(
      account_holder_name: nil,
      account_holder_type: nil,
      address_city: nil,
      address_country: nil,
      address_line1: nil,
      address_line2: nil,
      address_state: nil,
      address_zip: nil,
      exp_month: nil,
      exp_year: nil,
      expand: nil,
      metadata: nil,
      name: nil,
      owner: nil
    )
      @account_holder_name = account_holder_name
      @account_holder_type = account_holder_type
      @address_city = address_city
      @address_country = address_country
      @address_line1 = address_line1
      @address_line2 = address_line2
      @address_state = address_state
      @address_zip = address_zip
      @exp_month = exp_month
      @exp_year = exp_year
      @expand = expand
      @metadata = metadata
      @name = name
      @owner = owner
    end
  end
end
