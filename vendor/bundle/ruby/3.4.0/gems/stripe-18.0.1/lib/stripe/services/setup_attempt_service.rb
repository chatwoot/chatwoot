# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  class SetupAttemptService < StripeService
    # Returns a list of SetupAttempts that associate with a provided SetupIntent.
    def list(params = {}, opts = {})
      request(
        method: :get,
        path: "/v1/setup_attempts",
        params: params,
        opts: opts,
        base_address: :api
      )
    end
  end
end
