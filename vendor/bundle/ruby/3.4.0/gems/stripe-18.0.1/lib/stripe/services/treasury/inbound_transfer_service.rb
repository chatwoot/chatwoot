# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  module Treasury
    class InboundTransferService < StripeService
      # Cancels an InboundTransfer.
      def cancel(inbound_transfer, params = {}, opts = {})
        request(
          method: :post,
          path: format("/v1/treasury/inbound_transfers/%<inbound_transfer>s/cancel", { inbound_transfer: CGI.escape(inbound_transfer) }),
          params: params,
          opts: opts,
          base_address: :api
        )
      end

      # Creates an InboundTransfer.
      def create(params = {}, opts = {})
        request(
          method: :post,
          path: "/v1/treasury/inbound_transfers",
          params: params,
          opts: opts,
          base_address: :api
        )
      end

      # Returns a list of InboundTransfers sent from the specified FinancialAccount.
      def list(params = {}, opts = {})
        request(
          method: :get,
          path: "/v1/treasury/inbound_transfers",
          params: params,
          opts: opts,
          base_address: :api
        )
      end

      # Retrieves the details of an existing InboundTransfer.
      def retrieve(id, params = {}, opts = {})
        request(
          method: :get,
          path: format("/v1/treasury/inbound_transfers/%<id>s", { id: CGI.escape(id) }),
          params: params,
          opts: opts,
          base_address: :api
        )
      end
    end
  end
end
