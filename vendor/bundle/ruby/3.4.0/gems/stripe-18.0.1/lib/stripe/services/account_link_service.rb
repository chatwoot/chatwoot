# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  class AccountLinkService < StripeService
    # Creates an AccountLink object that includes a single-use Stripe URL that the platform can redirect their user to in order to take them through the Connect Onboarding flow.
    def create(params = {}, opts = {})
      request(
        method: :post,
        path: "/v1/account_links",
        params: params,
        opts: opts,
        base_address: :api
      )
    end
  end
end
