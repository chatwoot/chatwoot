# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  module Climate
    class OrderCreateParams < ::Stripe::RequestParams
      class Beneficiary < ::Stripe::RequestParams
        # Publicly displayable name for the end beneficiary of carbon removal.
        attr_accessor :public_name

        def initialize(public_name: nil)
          @public_name = public_name
        end
      end
      # Requested amount of carbon removal units. Either this or `metric_tons` must be specified.
      attr_accessor :amount
      # Publicly sharable reference for the end beneficiary of carbon removal. Assumed to be the Stripe account if not set.
      attr_accessor :beneficiary
      # Request currency for the order as a three-letter [ISO currency code](https://www.iso.org/iso-4217-currency-codes.html), in lowercase. Must be a supported [settlement currency for your account](https://stripe.com/docs/currencies). If omitted, the account's default currency will be used.
      attr_accessor :currency
      # Specifies which fields in the response should be expanded.
      attr_accessor :expand
      # Set of [key-value pairs](https://stripe.com/docs/api/metadata) that you can attach to an object. This can be useful for storing additional information about the object in a structured format. Individual keys can be unset by posting an empty value to them. All keys can be unset by posting an empty value to `metadata`.
      attr_accessor :metadata
      # Requested number of tons for the order. Either this or `amount` must be specified.
      attr_accessor :metric_tons
      # Unique identifier of the Climate product.
      attr_accessor :product

      def initialize(
        amount: nil,
        beneficiary: nil,
        currency: nil,
        expand: nil,
        metadata: nil,
        metric_tons: nil,
        product: nil
      )
        @amount = amount
        @beneficiary = beneficiary
        @currency = currency
        @expand = expand
        @metadata = metadata
        @metric_tons = metric_tons
        @product = product
      end
    end
  end
end
