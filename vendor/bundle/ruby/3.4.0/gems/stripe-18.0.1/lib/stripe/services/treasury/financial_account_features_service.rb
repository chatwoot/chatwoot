# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  module Treasury
    class FinancialAccountFeaturesService < StripeService
      # Retrieves Features information associated with the FinancialAccount.
      def retrieve(financial_account, params = {}, opts = {})
        request(
          method: :get,
          path: format("/v1/treasury/financial_accounts/%<financial_account>s/features", { financial_account: CGI.escape(financial_account) }),
          params: params,
          opts: opts,
          base_address: :api
        )
      end

      # Updates the Features associated with a FinancialAccount.
      def update(financial_account, params = {}, opts = {})
        request(
          method: :post,
          path: format("/v1/treasury/financial_accounts/%<financial_account>s/features", { financial_account: CGI.escape(financial_account) }),
          params: params,
          opts: opts,
          base_address: :api
        )
      end
    end
  end
end
