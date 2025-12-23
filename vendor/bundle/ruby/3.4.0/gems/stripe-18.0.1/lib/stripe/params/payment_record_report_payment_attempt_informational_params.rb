# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  class PaymentRecordReportPaymentAttemptInformationalParams < ::Stripe::RequestParams
    class CustomerDetails < ::Stripe::RequestParams
      # The customer who made the payment.
      attr_accessor :customer
      # The customer's phone number.
      attr_accessor :email
      # The customer's name.
      attr_accessor :name
      # The customer's phone number.
      attr_accessor :phone

      def initialize(customer: nil, email: nil, name: nil, phone: nil)
        @customer = customer
        @email = email
        @name = name
        @phone = phone
      end
    end

    class ShippingDetails < ::Stripe::RequestParams
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
      # The physical shipping address.
      attr_accessor :address
      # The shipping recipient's name.
      attr_accessor :name
      # The shipping recipient's phone number.
      attr_accessor :phone

      def initialize(address: nil, name: nil, phone: nil)
        @address = address
        @name = name
        @phone = phone
      end
    end
    # Customer information for this payment.
    attr_accessor :customer_details
    # An arbitrary string attached to the object. Often useful for displaying to users.
    attr_accessor :description
    # Specifies which fields in the response should be expanded.
    attr_accessor :expand
    # Set of [key-value pairs](https://stripe.com/docs/api/metadata) that you can attach to an object. This can be useful for storing additional information about the object in a structured format. Individual keys can be unset by posting an empty value to them. All keys can be unset by posting an empty value to `metadata`.
    attr_accessor :metadata
    # Shipping information for this payment.
    attr_accessor :shipping_details

    def initialize(
      customer_details: nil,
      description: nil,
      expand: nil,
      metadata: nil,
      shipping_details: nil
    )
      @customer_details = customer_details
      @description = description
      @expand = expand
      @metadata = metadata
      @shipping_details = shipping_details
    end
  end
end
