# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  module TestHelpers
    class CustomerService < StripeService
      # Create an incoming testmode bank transfer
      def fund_cash_balance(customer, params = {}, opts = {})
        request(
          method: :post,
          path: format("/v1/test_helpers/customers/%<customer>s/fund_cash_balance", { customer: CGI.escape(customer) }),
          params: params,
          opts: opts,
          base_address: :api
        )
      end
    end
  end
end
