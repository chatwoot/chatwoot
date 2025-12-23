# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  class ConfirmationTokenService < StripeService
    # Retrieves an existing ConfirmationToken object
    def retrieve(confirmation_token, params = {}, opts = {})
      request(
        method: :get,
        path: format("/v1/confirmation_tokens/%<confirmation_token>s", { confirmation_token: CGI.escape(confirmation_token) }),
        params: params,
        opts: opts,
        base_address: :api
      )
    end
  end
end
