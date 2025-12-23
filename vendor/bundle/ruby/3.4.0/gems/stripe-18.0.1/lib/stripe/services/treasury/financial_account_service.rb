# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  module Treasury
    class FinancialAccountService < StripeService
      attr_reader :features

      def initialize(requestor)
        super
        @features = Stripe::Treasury::FinancialAccountFeaturesService.new(@requestor)
      end

      # Closes a FinancialAccount. A FinancialAccount can only be closed if it has a zero balance, has no pending InboundTransfers, and has canceled all attached Issuing cards.
      def close(financial_account, params = {}, opts = {})
        request(
          method: :post,
          path: format("/v1/treasury/financial_accounts/%<financial_account>s/close", { financial_account: CGI.escape(financial_account) }),
          params: params,
          opts: opts,
          base_address: :api
        )
      end

      # Creates a new FinancialAccount. Each connected account can have up to three FinancialAccounts by default.
      def create(params = {}, opts = {})
        request(
          method: :post,
          path: "/v1/treasury/financial_accounts",
          params: params,
          opts: opts,
          base_address: :api
        )
      end

      # Returns a list of FinancialAccounts.
      def list(params = {}, opts = {})
        request(
          method: :get,
          path: "/v1/treasury/financial_accounts",
          params: params,
          opts: opts,
          base_address: :api
        )
      end

      # Retrieves the details of a FinancialAccount.
      def retrieve(financial_account, params = {}, opts = {})
        request(
          method: :get,
          path: format("/v1/treasury/financial_accounts/%<financial_account>s", { financial_account: CGI.escape(financial_account) }),
          params: params,
          opts: opts,
          base_address: :api
        )
      end

      # Updates the details of a FinancialAccount.
      def update(financial_account, params = {}, opts = {})
        request(
          method: :post,
          path: format("/v1/treasury/financial_accounts/%<financial_account>s", { financial_account: CGI.escape(financial_account) }),
          params: params,
          opts: opts,
          base_address: :api
        )
      end
    end
  end
end
