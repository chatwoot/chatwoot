# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  module Climate
    class OrderService < StripeService
      # Cancels a Climate order. You can cancel an order within 24 hours of creation. Stripe refunds the
      # reservation amount_subtotal, but not the amount_fees for user-triggered cancellations. Frontier
      # might cancel reservations if suppliers fail to deliver. If Frontier cancels the reservation, Stripe
      # provides 90 days advance notice and refunds the amount_total.
      def cancel(order, params = {}, opts = {})
        request(
          method: :post,
          path: format("/v1/climate/orders/%<order>s/cancel", { order: CGI.escape(order) }),
          params: params,
          opts: opts,
          base_address: :api
        )
      end

      # Creates a Climate order object for a given Climate product. The order will be processed immediately
      # after creation and payment will be deducted your Stripe balance.
      def create(params = {}, opts = {})
        request(
          method: :post,
          path: "/v1/climate/orders",
          params: params,
          opts: opts,
          base_address: :api
        )
      end

      # Lists all Climate order objects. The orders are returned sorted by creation date, with the
      # most recently created orders appearing first.
      def list(params = {}, opts = {})
        request(
          method: :get,
          path: "/v1/climate/orders",
          params: params,
          opts: opts,
          base_address: :api
        )
      end

      # Retrieves the details of a Climate order object with the given ID.
      def retrieve(order, params = {}, opts = {})
        request(
          method: :get,
          path: format("/v1/climate/orders/%<order>s", { order: CGI.escape(order) }),
          params: params,
          opts: opts,
          base_address: :api
        )
      end

      # Updates the specified order by setting the values of the parameters passed.
      def update(order, params = {}, opts = {})
        request(
          method: :post,
          path: format("/v1/climate/orders/%<order>s", { order: CGI.escape(order) }),
          params: params,
          opts: opts,
          base_address: :api
        )
      end
    end
  end
end
