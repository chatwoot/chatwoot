# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  class PaymentRecordReportPaymentAttemptParams < ::Stripe::RequestParams
    class Failed < ::Stripe::RequestParams
      # When the reported payment failed. Measured in seconds since the Unix epoch.
      attr_accessor :failed_at

      def initialize(failed_at: nil)
        @failed_at = failed_at
      end
    end

    class Guaranteed < ::Stripe::RequestParams
      # When the reported payment was guaranteed. Measured in seconds since the Unix epoch.
      attr_accessor :guaranteed_at

      def initialize(guaranteed_at: nil)
        @guaranteed_at = guaranteed_at
      end
    end

    class PaymentMethodDetails < ::Stripe::RequestParams
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
        # The billing address associated with the method of payment.
        attr_accessor :address
        # The billing email associated with the method of payment.
        attr_accessor :email
        # The billing name associated with the method of payment.
        attr_accessor :name
        # The billing phone number associated with the method of payment.
        attr_accessor :phone

        def initialize(address: nil, email: nil, name: nil, phone: nil)
          @address = address
          @email = email
          @name = name
          @phone = phone
        end
      end

      class Custom < ::Stripe::RequestParams
        # Display name for the custom (user-defined) payment method type used to make this payment.
        attr_accessor :display_name
        # The custom payment method type associated with this payment.
        attr_accessor :type

        def initialize(display_name: nil, type: nil)
          @display_name = display_name
          @type = type
        end
      end
      # The billing details associated with the method of payment.
      attr_accessor :billing_details
      # Information about the custom (user-defined) payment method used to make this payment.
      attr_accessor :custom
      # ID of the Stripe Payment Method used to make this payment.
      attr_accessor :payment_method
      # The type of the payment method details. An additional hash is included on the payment_method_details with a name matching this value. It contains additional information specific to the type.
      attr_accessor :type

      def initialize(billing_details: nil, custom: nil, payment_method: nil, type: nil)
        @billing_details = billing_details
        @custom = custom
        @payment_method = payment_method
        @type = type
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
    # An arbitrary string attached to the object. Often useful for displaying to users.
    attr_accessor :description
    # Specifies which fields in the response should be expanded.
    attr_accessor :expand
    # Information about the payment attempt failure.
    attr_accessor :failed
    # Information about the payment attempt guarantee.
    attr_accessor :guaranteed
    # When the reported payment was initiated. Measured in seconds since the Unix epoch.
    attr_accessor :initiated_at
    # Set of [key-value pairs](https://stripe.com/docs/api/metadata) that you can attach to an object. This can be useful for storing additional information about the object in a structured format. Individual keys can be unset by posting an empty value to them. All keys can be unset by posting an empty value to `metadata`.
    attr_accessor :metadata
    # The outcome of the reported payment.
    attr_accessor :outcome
    # Information about the Payment Method debited for this payment.
    attr_accessor :payment_method_details
    # Shipping information for this payment.
    attr_accessor :shipping_details

    def initialize(
      description: nil,
      expand: nil,
      failed: nil,
      guaranteed: nil,
      initiated_at: nil,
      metadata: nil,
      outcome: nil,
      payment_method_details: nil,
      shipping_details: nil
    )
      @description = description
      @expand = expand
      @failed = failed
      @guaranteed = guaranteed
      @initiated_at = initiated_at
      @metadata = metadata
      @outcome = outcome
      @payment_method_details = payment_method_details
      @shipping_details = shipping_details
    end
  end
end
