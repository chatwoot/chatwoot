# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  module Climate
    # Orders represent your intent to purchase a particular Climate product. When you create an order, the
    # payment is deducted from your merchant balance.
    class Order < APIResource
      extend Stripe::APIOperations::Create
      extend Stripe::APIOperations::List
      include Stripe::APIOperations::Save

      OBJECT_NAME = "climate.order"
      def self.object_name
        "climate.order"
      end

      class Beneficiary < ::Stripe::StripeObject
        # Publicly displayable name for the end beneficiary of carbon removal.
        attr_reader :public_name

        def self.inner_class_types
          @inner_class_types = {}
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end

      class DeliveryDetail < ::Stripe::StripeObject
        class Location < ::Stripe::StripeObject
          # The city where the supplier is located.
          attr_reader :city
          # Two-letter ISO code representing the country where the supplier is located.
          attr_reader :country
          # The geographic latitude where the supplier is located.
          attr_reader :latitude
          # The geographic longitude where the supplier is located.
          attr_reader :longitude
          # The state/county/province/region where the supplier is located.
          attr_reader :region

          def self.inner_class_types
            @inner_class_types = {}
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end
        # Time at which the delivery occurred. Measured in seconds since the Unix epoch.
        attr_reader :delivered_at
        # Specific location of this delivery.
        attr_reader :location
        # Quantity of carbon removal supplied by this delivery.
        attr_reader :metric_tons
        # Once retired, a URL to the registry entry for the tons from this delivery.
        attr_reader :registry_url
        # A supplier of carbon removal.
        attr_reader :supplier

        def self.inner_class_types
          @inner_class_types = { location: Location }
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end
      # Total amount of [Frontier](https://frontierclimate.com/)'s service fees in the currency's smallest unit.
      attr_reader :amount_fees
      # Total amount of the carbon removal in the currency's smallest unit.
      attr_reader :amount_subtotal
      # Total amount of the order including fees in the currency's smallest unit.
      attr_reader :amount_total
      # Attribute for field beneficiary
      attr_reader :beneficiary
      # Time at which the order was canceled. Measured in seconds since the Unix epoch.
      attr_reader :canceled_at
      # Reason for the cancellation of this order.
      attr_reader :cancellation_reason
      # For delivered orders, a URL to a delivery certificate for the order.
      attr_reader :certificate
      # Time at which the order was confirmed. Measured in seconds since the Unix epoch.
      attr_reader :confirmed_at
      # Time at which the object was created. Measured in seconds since the Unix epoch.
      attr_reader :created
      # Three-letter [ISO currency code](https://www.iso.org/iso-4217-currency-codes.html), in lowercase, representing the currency for this order.
      attr_reader :currency
      # Time at which the order's expected_delivery_year was delayed. Measured in seconds since the Unix epoch.
      attr_reader :delayed_at
      # Time at which the order was delivered. Measured in seconds since the Unix epoch.
      attr_reader :delivered_at
      # Details about the delivery of carbon removal for this order.
      attr_reader :delivery_details
      # The year this order is expected to be delivered.
      attr_reader :expected_delivery_year
      # Unique identifier for the object.
      attr_reader :id
      # Has the value `true` if the object exists in live mode or the value `false` if the object exists in test mode.
      attr_reader :livemode
      # Set of [key-value pairs](https://stripe.com/docs/api/metadata) that you can attach to an object. This can be useful for storing additional information about the object in a structured format.
      attr_reader :metadata
      # Quantity of carbon removal that is included in this order.
      attr_reader :metric_tons
      # String representing the object's type. Objects of the same type share the same value.
      attr_reader :object
      # Unique ID for the Climate `Product` this order is purchasing.
      attr_reader :product
      # Time at which the order's product was substituted for a different product. Measured in seconds since the Unix epoch.
      attr_reader :product_substituted_at
      # The current status of this order.
      attr_reader :status

      # Cancels a Climate order. You can cancel an order within 24 hours of creation. Stripe refunds the
      # reservation amount_subtotal, but not the amount_fees for user-triggered cancellations. Frontier
      # might cancel reservations if suppliers fail to deliver. If Frontier cancels the reservation, Stripe
      # provides 90 days advance notice and refunds the amount_total.
      def cancel(params = {}, opts = {})
        request_stripe_object(
          method: :post,
          path: format("/v1/climate/orders/%<order>s/cancel", { order: CGI.escape(self["id"]) }),
          params: params,
          opts: opts
        )
      end

      # Cancels a Climate order. You can cancel an order within 24 hours of creation. Stripe refunds the
      # reservation amount_subtotal, but not the amount_fees for user-triggered cancellations. Frontier
      # might cancel reservations if suppliers fail to deliver. If Frontier cancels the reservation, Stripe
      # provides 90 days advance notice and refunds the amount_total.
      def self.cancel(order, params = {}, opts = {})
        request_stripe_object(
          method: :post,
          path: format("/v1/climate/orders/%<order>s/cancel", { order: CGI.escape(order) }),
          params: params,
          opts: opts
        )
      end

      # Creates a Climate order object for a given Climate product. The order will be processed immediately
      # after creation and payment will be deducted your Stripe balance.
      def self.create(params = {}, opts = {})
        request_stripe_object(method: :post, path: "/v1/climate/orders", params: params, opts: opts)
      end

      # Lists all Climate order objects. The orders are returned sorted by creation date, with the
      # most recently created orders appearing first.
      def self.list(params = {}, opts = {})
        request_stripe_object(method: :get, path: "/v1/climate/orders", params: params, opts: opts)
      end

      # Updates the specified order by setting the values of the parameters passed.
      def self.update(order, params = {}, opts = {})
        request_stripe_object(
          method: :post,
          path: format("/v1/climate/orders/%<order>s", { order: CGI.escape(order) }),
          params: params,
          opts: opts
        )
      end

      def self.inner_class_types
        @inner_class_types = { beneficiary: Beneficiary, delivery_details: DeliveryDetail }
      end

      def self.field_remappings
        @field_remappings = {}
      end
    end
  end
end
