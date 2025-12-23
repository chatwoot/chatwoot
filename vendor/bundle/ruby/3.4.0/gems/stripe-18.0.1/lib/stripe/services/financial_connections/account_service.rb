# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  module FinancialConnections
    class AccountService < StripeService
      attr_reader :owners

      def initialize(requestor)
        super
        @owners = Stripe::FinancialConnections::AccountOwnerService.new(@requestor)
      end

      # Disables your access to a Financial Connections Account. You will no longer be able to access data associated with the account (e.g. balances, transactions).
      def disconnect(account, params = {}, opts = {})
        request(
          method: :post,
          path: format("/v1/financial_connections/accounts/%<account>s/disconnect", { account: CGI.escape(account) }),
          params: params,
          opts: opts,
          base_address: :api
        )
      end

      # Returns a list of Financial Connections Account objects.
      def list(params = {}, opts = {})
        request(
          method: :get,
          path: "/v1/financial_connections/accounts",
          params: params,
          opts: opts,
          base_address: :api
        )
      end

      # Refreshes the data associated with a Financial Connections Account.
      def refresh(account, params = {}, opts = {})
        request(
          method: :post,
          path: format("/v1/financial_connections/accounts/%<account>s/refresh", { account: CGI.escape(account) }),
          params: params,
          opts: opts,
          base_address: :api
        )
      end

      # Retrieves the details of an Financial Connections Account.
      def retrieve(account, params = {}, opts = {})
        request(
          method: :get,
          path: format("/v1/financial_connections/accounts/%<account>s", { account: CGI.escape(account) }),
          params: params,
          opts: opts,
          base_address: :api
        )
      end

      # Subscribes to periodic refreshes of data associated with a Financial Connections Account. When the account status is active, data is typically refreshed once a day.
      def subscribe(account, params = {}, opts = {})
        request(
          method: :post,
          path: format("/v1/financial_connections/accounts/%<account>s/subscribe", { account: CGI.escape(account) }),
          params: params,
          opts: opts,
          base_address: :api
        )
      end

      # Unsubscribes from periodic refreshes of data associated with a Financial Connections Account.
      def unsubscribe(account, params = {}, opts = {})
        request(
          method: :post,
          path: format("/v1/financial_connections/accounts/%<account>s/unsubscribe", { account: CGI.escape(account) }),
          params: params,
          opts: opts,
          base_address: :api
        )
      end
    end
  end
end
