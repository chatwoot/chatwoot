# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  module Treasury
    class ReceivedCreditService < StripeService
      # Returns a list of ReceivedCredits.
      def list(params = {}, opts = {})
        request(
          method: :get,
          path: "/v1/treasury/received_credits",
          params: params,
          opts: opts,
          base_address: :api
        )
      end

      # Retrieves the details of an existing ReceivedCredit by passing the unique ReceivedCredit ID from the ReceivedCredit list.
      def retrieve(id, params = {}, opts = {})
        request(
          method: :get,
          path: format("/v1/treasury/received_credits/%<id>s", { id: CGI.escape(id) }),
          params: params,
          opts: opts,
          base_address: :api
        )
      end
    end
  end
end
