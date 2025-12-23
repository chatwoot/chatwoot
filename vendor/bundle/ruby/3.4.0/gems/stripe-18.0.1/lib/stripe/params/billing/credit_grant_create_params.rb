# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  module Billing
    class CreditGrantCreateParams < ::Stripe::RequestParams
      class Amount < ::Stripe::RequestParams
        class Monetary < ::Stripe::RequestParams
          # Three-letter [ISO code for the currency](https://stripe.com/docs/currencies) of the `value` parameter.
          attr_accessor :currency
          # A positive integer representing the amount of the credit grant.
          attr_accessor :value

          def initialize(currency: nil, value: nil)
            @currency = currency
            @value = value
          end
        end
        # The monetary amount.
        attr_accessor :monetary
        # The type of this amount. We currently only support `monetary` billing credits.
        attr_accessor :type

        def initialize(monetary: nil, type: nil)
          @monetary = monetary
          @type = type
        end
      end

      class ApplicabilityConfig < ::Stripe::RequestParams
        class Scope < ::Stripe::RequestParams
          class Price < ::Stripe::RequestParams
            # The price ID this credit grant should apply to.
            attr_accessor :id

            def initialize(id: nil)
              @id = id
            end
          end
          # The price type that credit grants can apply to. We currently only support the `metered` price type. Cannot be used in combination with `prices`.
          attr_accessor :price_type
          # A list of prices that the credit grant can apply to. We currently only support the `metered` prices. Cannot be used in combination with `price_type`.
          attr_accessor :prices

          def initialize(price_type: nil, prices: nil)
            @price_type = price_type
            @prices = prices
          end
        end
        # Specify the scope of this applicability config.
        attr_accessor :scope

        def initialize(scope: nil)
          @scope = scope
        end
      end
      # Amount of this credit grant.
      attr_accessor :amount
      # Configuration specifying what this credit grant applies to. We currently only support `metered` prices that have a [Billing Meter](https://docs.stripe.com/api/billing/meter) attached to them.
      attr_accessor :applicability_config
      # The category of this credit grant. It defaults to `paid` if not specified.
      attr_accessor :category
      # ID of the customer to receive the billing credits.
      attr_accessor :customer
      # The time when the billing credits become effective-when they're eligible for use. It defaults to the current timestamp if not specified.
      attr_accessor :effective_at
      # Specifies which fields in the response should be expanded.
      attr_accessor :expand
      # The time when the billing credits expire. If not specified, the billing credits don't expire.
      attr_accessor :expires_at
      # Set of key-value pairs that you can attach to an object. You can use this to store additional information about the object (for example, cost basis) in a structured format.
      attr_accessor :metadata
      # A descriptive name shown in the Dashboard.
      attr_accessor :name
      # The desired priority for applying this credit grant. If not specified, it will be set to the default value of 50. The highest priority is 0 and the lowest is 100.
      attr_accessor :priority

      def initialize(
        amount: nil,
        applicability_config: nil,
        category: nil,
        customer: nil,
        effective_at: nil,
        expand: nil,
        expires_at: nil,
        metadata: nil,
        name: nil,
        priority: nil
      )
        @amount = amount
        @applicability_config = applicability_config
        @category = category
        @customer = customer
        @effective_at = effective_at
        @expand = expand
        @expires_at = expires_at
        @metadata = metadata
        @name = name
        @priority = priority
      end
    end
  end
end
