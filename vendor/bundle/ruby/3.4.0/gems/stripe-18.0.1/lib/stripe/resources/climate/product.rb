# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  module Climate
    # A Climate product represents a type of carbon removal unit available for reservation.
    # You can retrieve it to see the current price and availability.
    class Product < APIResource
      extend Stripe::APIOperations::List

      OBJECT_NAME = "climate.product"
      def self.object_name
        "climate.product"
      end

      class CurrentPricesPerMetricTon < ::Stripe::StripeObject
        # Fees for one metric ton of carbon removal in the currency's smallest unit.
        attr_reader :amount_fees
        # Subtotal for one metric ton of carbon removal (excluding fees) in the currency's smallest unit.
        attr_reader :amount_subtotal
        # Total for one metric ton of carbon removal (including fees) in the currency's smallest unit.
        attr_reader :amount_total

        def self.inner_class_types
          @inner_class_types = {}
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end
      # Time at which the object was created. Measured in seconds since the Unix epoch.
      attr_reader :created
      # Current prices for a metric ton of carbon removal in a currency's smallest unit.
      attr_reader :current_prices_per_metric_ton
      # The year in which the carbon removal is expected to be delivered.
      attr_reader :delivery_year
      # Unique identifier for the object. For convenience, Climate product IDs are human-readable strings
      # that start with `climsku_`. See [carbon removal inventory](https://stripe.com/docs/climate/orders/carbon-removal-inventory)
      # for a list of available carbon removal products.
      attr_reader :id
      # Has the value `true` if the object exists in live mode or the value `false` if the object exists in test mode.
      attr_reader :livemode
      # The quantity of metric tons available for reservation.
      attr_reader :metric_tons_available
      # The Climate product's name.
      attr_reader :name
      # String representing the object's type. Objects of the same type share the same value.
      attr_reader :object
      # The carbon removal suppliers that fulfill orders for this Climate product.
      attr_reader :suppliers

      # Lists all available Climate product objects.
      def self.list(params = {}, opts = {})
        request_stripe_object(
          method: :get,
          path: "/v1/climate/products",
          params: params,
          opts: opts
        )
      end

      def self.inner_class_types
        @inner_class_types = { current_prices_per_metric_ton: CurrentPricesPerMetricTon }
      end

      def self.field_remappings
        @field_remappings = {}
      end
    end
  end
end
