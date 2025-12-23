# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  module Treasury
    class OutboundTransferService < StripeService
      # An OutboundTransfer can be canceled if the funds have not yet been paid out.
      def cancel(outbound_transfer, params = {}, opts = {})
        request(
          method: :post,
          path: format("/v1/treasury/outbound_transfers/%<outbound_transfer>s/cancel", { outbound_transfer: CGI.escape(outbound_transfer) }),
          params: params,
          opts: opts,
          base_address: :api
        )
      end

      # Creates an OutboundTransfer.
      def create(params = {}, opts = {})
        request(
          method: :post,
          path: "/v1/treasury/outbound_transfers",
          params: params,
          opts: opts,
          base_address: :api
        )
      end

      # Returns a list of OutboundTransfers sent from the specified FinancialAccount.
      def list(params = {}, opts = {})
        request(
          method: :get,
          path: "/v1/treasury/outbound_transfers",
          params: params,
          opts: opts,
          base_address: :api
        )
      end

      # Retrieves the details of an existing OutboundTransfer by passing the unique OutboundTransfer ID from either the OutboundTransfer creation request or OutboundTransfer list.
      def retrieve(outbound_transfer, params = {}, opts = {})
        request(
          method: :get,
          path: format("/v1/treasury/outbound_transfers/%<outbound_transfer>s", { outbound_transfer: CGI.escape(outbound_transfer) }),
          params: params,
          opts: opts,
          base_address: :api
        )
      end
    end
  end
end
