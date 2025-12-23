# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  module TestHelpers
    module Treasury
      class InboundTransferService < StripeService
        # Transitions a test mode created InboundTransfer to the failed status. The InboundTransfer must already be in the processing state.
        def fail(id, params = {}, opts = {})
          request(
            method: :post,
            path: format("/v1/test_helpers/treasury/inbound_transfers/%<id>s/fail", { id: CGI.escape(id) }),
            params: params,
            opts: opts,
            base_address: :api
          )
        end

        # Marks the test mode InboundTransfer object as returned and links the InboundTransfer to a ReceivedDebit. The InboundTransfer must already be in the succeeded state.
        def return_inbound_transfer(id, params = {}, opts = {})
          request(
            method: :post,
            path: format("/v1/test_helpers/treasury/inbound_transfers/%<id>s/return", { id: CGI.escape(id) }),
            params: params,
            opts: opts,
            base_address: :api
          )
        end

        # Transitions a test mode created InboundTransfer to the succeeded status. The InboundTransfer must already be in the processing state.
        def succeed(id, params = {}, opts = {})
          request(
            method: :post,
            path: format("/v1/test_helpers/treasury/inbound_transfers/%<id>s/succeed", { id: CGI.escape(id) }),
            params: params,
            opts: opts,
            base_address: :api
          )
        end
      end
    end
  end
end
