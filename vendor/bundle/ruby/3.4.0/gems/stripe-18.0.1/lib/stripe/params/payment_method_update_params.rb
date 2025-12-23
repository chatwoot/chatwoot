# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  class PaymentMethodUpdateParams < ::Stripe::RequestParams
    class BillingDetails < ::Stripe::RequestParams
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
      # Billing address.
      attr_accessor :address
      # Email address.
      attr_accessor :email
      # Full name.
      attr_accessor :name
      # Billing phone number (including extension).
      attr_accessor :phone
      # Taxpayer identification number. Used only for transactions between LATAM buyers and non-LATAM sellers.
      attr_accessor :tax_id

      def initialize(address: nil, email: nil, name: nil, phone: nil, tax_id: nil)
        @address = address
        @email = email
        @name = name
        @phone = phone
        @tax_id = tax_id
      end
    end

    class Card < ::Stripe::RequestParams
      class Networks < ::Stripe::RequestParams
        # The customer's preferred card network for co-branded cards. Supports `cartes_bancaires`, `mastercard`, or `visa`. Selection of a network that does not apply to the card will be stored as `invalid_preference` on the card.
        attr_accessor :preferred

        def initialize(preferred: nil)
          @preferred = preferred
        end
      end
      # Two-digit number representing the card's expiration month.
      attr_accessor :exp_month
      # Four-digit number representing the card's expiration year.
      attr_accessor :exp_year
      # Contains information about card networks used to process the payment.
      attr_accessor :networks

      def initialize(exp_month: nil, exp_year: nil, networks: nil)
        @exp_month = exp_month
        @exp_year = exp_year
        @networks = networks
      end
    end

    class UsBankAccount < ::Stripe::RequestParams
      # Bank account holder type.
      attr_accessor :account_holder_type
      # Bank account type.
      attr_accessor :account_type

      def initialize(account_holder_type: nil, account_type: nil)
        @account_holder_type = account_holder_type
        @account_type = account_type
      end
    end
    # This field indicates whether this payment method can be shown again to its customer in a checkout flow. Stripe products such as Checkout and Elements use this field to determine whether a payment method can be shown as a saved payment method in a checkout flow. The field defaults to `unspecified`.
    attr_accessor :allow_redisplay
    # Billing information associated with the PaymentMethod that may be used or required by particular types of payment methods.
    attr_accessor :billing_details
    # If this is a `card` PaymentMethod, this hash contains the user's card details.
    attr_accessor :card
    # Specifies which fields in the response should be expanded.
    attr_accessor :expand
    # Set of [key-value pairs](https://stripe.com/docs/api/metadata) that you can attach to an object. This can be useful for storing additional information about the object in a structured format. Individual keys can be unset by posting an empty value to them. All keys can be unset by posting an empty value to `metadata`.
    attr_accessor :metadata
    # If this is an `us_bank_account` PaymentMethod, this hash contains details about the US bank account payment method.
    attr_accessor :us_bank_account

    def initialize(
      allow_redisplay: nil,
      billing_details: nil,
      card: nil,
      expand: nil,
      metadata: nil,
      us_bank_account: nil
    )
      @allow_redisplay = allow_redisplay
      @billing_details = billing_details
      @card = card
      @expand = expand
      @metadata = metadata
      @us_bank_account = us_bank_account
    end
  end
end
