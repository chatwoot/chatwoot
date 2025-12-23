# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  class CustomerCashBalanceService < StripeService
    # Retrieves a customer's cash balance.
    def retrieve(customer, params = {}, opts = {})
      request(
        method: :get,
        path: format("/v1/customers/%<customer>s/cash_balance", { customer: CGI.escape(customer) }),
        params: params,
        opts: opts,
        base_address: :api
      )
    end

    # Changes the settings on a customer's cash balance.
    def update(customer, params = {}, opts = {})
      request(
        method: :post,
        path: format("/v1/customers/%<customer>s/cash_balance", { customer: CGI.escape(customer) }),
        params: params,
        opts: opts,
        base_address: :api
      )
    end
  end
end
