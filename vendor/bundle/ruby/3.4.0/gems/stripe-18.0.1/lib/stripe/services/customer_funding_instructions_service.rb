# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  class CustomerFundingInstructionsService < StripeService
    # Retrieve funding instructions for a customer cash balance. If funding instructions do not yet exist for the customer, new
    # funding instructions will be created. If funding instructions have already been created for a given customer, the same
    # funding instructions will be retrieved. In other words, we will return the same funding instructions each time.
    def create(customer, params = {}, opts = {})
      request(
        method: :post,
        path: format("/v1/customers/%<customer>s/funding_instructions", { customer: CGI.escape(customer) }),
        params: params,
        opts: opts,
        base_address: :api
      )
    end
  end
end
