# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  module Treasury
    class OutboundPaymentService < StripeService
      # Cancel an OutboundPayment.
      def cancel(id, params = {}, opts = {})
        request(
          method: :post,
          path: format("/v1/treasury/outbound_payments/%<id>s/cancel", { id: CGI.escape(id) }),
          params: params,
          opts: opts,
          base_address: :api
        )
      end

      # Creates an OutboundPayment.
      def create(params = {}, opts = {})
        request(
          method: :post,
          path: "/v1/treasury/outbound_payments",
          params: params,
          opts: opts,
          base_address: :api
        )
      end

      # Returns a list of OutboundPayments sent from the specified FinancialAccount.
      def list(params = {}, opts = {})
        request(
          method: :get,
          path: "/v1/treasury/outbound_payments",
          params: params,
          opts: opts,
          base_address: :api
        )
      end

      # Retrieves the details of an existing OutboundPayment by passing the unique OutboundPayment ID from either the OutboundPayment creation request or OutboundPayment list.
      def retrieve(id, params = {}, opts = {})
        request(
          method: :get,
          path: format("/v1/treasury/outbound_payments/%<id>s", { id: CGI.escape(id) }),
          params: params,
          opts: opts,
          base_address: :api
        )
      end
    end
  end
end
