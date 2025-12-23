# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  class CustomerSessionService < StripeService
    # Creates a Customer Session object that includes a single-use client secret that you can use on your front-end to grant client-side API access for certain customer resources.
    def create(params = {}, opts = {})
      request(
        method: :post,
        path: "/v1/customer_sessions",
        params: params,
        opts: opts,
        base_address: :api
      )
    end
  end
end
