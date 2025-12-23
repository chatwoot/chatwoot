# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  module FinancialConnections
    class AccountOwnerService < StripeService
      # Lists all owners for a given Account
      def list(account, params = {}, opts = {})
        request(
          method: :get,
          path: format("/v1/financial_connections/accounts/%<account>s/owners", { account: CGI.escape(account) }),
          params: params,
          opts: opts,
          base_address: :api
        )
      end
    end
  end
end
