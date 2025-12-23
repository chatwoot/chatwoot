# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  class CustomerCashBalanceTransactionService < StripeService
    # Returns a list of transactions that modified the customer's [cash balance](https://docs.stripe.com/docs/payments/customer-balance).
    def list(customer, params = {}, opts = {})
      request(
        method: :get,
        path: format("/v1/customers/%<customer>s/cash_balance_transactions", { customer: CGI.escape(customer) }),
        params: params,
        opts: opts,
        base_address: :api
      )
    end

    # Retrieves a specific cash balance transaction, which updated the customer's [cash balance](https://docs.stripe.com/docs/payments/customer-balance).
    def retrieve(customer, transaction, params = {}, opts = {})
      request(
        method: :get,
        path: format("/v1/customers/%<customer>s/cash_balance_transactions/%<transaction>s", { customer: CGI.escape(customer), transaction: CGI.escape(transaction) }),
        params: params,
        opts: opts,
        base_address: :api
      )
    end
  end
end
