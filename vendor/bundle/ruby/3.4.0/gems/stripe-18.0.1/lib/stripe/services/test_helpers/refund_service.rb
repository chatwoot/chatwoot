# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  module TestHelpers
    class RefundService < StripeService
      # Expire a refund with a status of requires_action.
      def expire(refund, params = {}, opts = {})
        request(
          method: :post,
          path: format("/v1/test_helpers/refunds/%<refund>s/expire", { refund: CGI.escape(refund) }),
          params: params,
          opts: opts,
          base_address: :api
        )
      end
    end
  end
end
