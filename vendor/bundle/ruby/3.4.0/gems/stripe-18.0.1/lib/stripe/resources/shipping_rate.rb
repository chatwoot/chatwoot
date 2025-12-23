# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  # Shipping rates describe the price of shipping presented to your customers and
  # applied to a purchase. For more information, see [Charge for shipping](https://stripe.com/docs/payments/during-payment/charge-shipping).
  class ShippingRate < APIResource
    extend Stripe::APIOperations::Create
    extend Stripe::APIOperations::List
    include Stripe::APIOperations::Save

    OBJECT_NAME = "shipping_rate"
    def self.object_name
      "shipping_rate"
    end

    class DeliveryEstimate < ::Stripe::StripeObject
      class Maximum < ::Stripe::StripeObject
        # A unit of time.
        attr_reader :unit
        # Must be greater than 0.
        attr_reader :value

        def self.inner_class_types
          @inner_class_types = {}
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end

      class Minimum < ::Stripe::StripeObject
        # A unit of time.
        attr_reader :unit
        # Must be greater than 0.
        attr_reader :value

        def self.inner_class_types
          @inner_class_types = {}
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end
      # The upper bound of the estimated range. If empty, represents no upper bound i.e., infinite.
      attr_reader :maximum
      # The lower bound of the estimated range. If empty, represents no lower bound.
      attr_reader :minimum

      def self.inner_class_types
        @inner_class_types = { maximum: Maximum, minimum: Minimum }
      end

      def self.field_remappings
        @field_remappings = {}
      end
    end

    class FixedAmount < ::Stripe::StripeObject
      class CurrencyOptions < ::Stripe::StripeObject
        # A non-negative integer in cents representing how much to charge.
        attr_reader :amount
        # Specifies whether the rate is considered inclusive of taxes or exclusive of taxes. One of `inclusive`, `exclusive`, or `unspecified`.
        attr_reader :tax_behavior

        def self.inner_class_types
          @inner_class_types = {}
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end
      # A non-negative integer in cents representing how much to charge.
      attr_reader :amount
      # Three-letter [ISO currency code](https://www.iso.org/iso-4217-currency-codes.html), in lowercase. Must be a [supported currency](https://stripe.com/docs/currencies).
      attr_reader :currency
      # Shipping rates defined in each available currency option. Each key must be a three-letter [ISO currency code](https://www.iso.org/iso-4217-currency-codes.html) and a [supported currency](https://stripe.com/docs/currencies).
      attr_reader :currency_options

      def self.inner_class_types
        @inner_class_types = { currency_options: CurrencyOptions }
      end

      def self.field_remappings
        @field_remappings = {}
      end
    end
    # Whether the shipping rate can be used for new purchases. Defaults to `true`.
    attr_reader :active
    # Time at which the object was created. Measured in seconds since the Unix epoch.
    attr_reader :created
    # The estimated range for how long shipping will take, meant to be displayable to the customer. This will appear on CheckoutSessions.
    attr_reader :delivery_estimate
    # The name of the shipping rate, meant to be displayable to the customer. This will appear on CheckoutSessions.
    attr_reader :display_name
    # Attribute for field fixed_amount
    attr_reader :fixed_amount
    # Unique identifier for the object.
    attr_reader :id
    # Has the value `true` if the object exists in live mode or the value `false` if the object exists in test mode.
    attr_reader :livemode
    # Set of [key-value pairs](https://stripe.com/docs/api/metadata) that you can attach to an object. This can be useful for storing additional information about the object in a structured format.
    attr_reader :metadata
    # String representing the object's type. Objects of the same type share the same value.
    attr_reader :object
    # Specifies whether the rate is considered inclusive of taxes or exclusive of taxes. One of `inclusive`, `exclusive`, or `unspecified`.
    attr_reader :tax_behavior
    # A [tax code](https://stripe.com/docs/tax/tax-categories) ID. The Shipping tax code is `txcd_92010001`.
    attr_reader :tax_code
    # The type of calculation to use on the shipping rate.
    attr_reader :type

    # Creates a new shipping rate object.
    def self.create(params = {}, opts = {})
      request_stripe_object(method: :post, path: "/v1/shipping_rates", params: params, opts: opts)
    end

    # Returns a list of your shipping rates.
    def self.list(params = {}, opts = {})
      request_stripe_object(method: :get, path: "/v1/shipping_rates", params: params, opts: opts)
    end

    # Updates an existing shipping rate object.
    def self.update(shipping_rate_token, params = {}, opts = {})
      request_stripe_object(
        method: :post,
        path: format("/v1/shipping_rates/%<shipping_rate_token>s", { shipping_rate_token: CGI.escape(shipping_rate_token) }),
        params: params,
        opts: opts
      )
    end

    def self.inner_class_types
      @inner_class_types = { delivery_estimate: DeliveryEstimate, fixed_amount: FixedAmount }
    end

    def self.field_remappings
      @field_remappings = {}
    end
  end
end
