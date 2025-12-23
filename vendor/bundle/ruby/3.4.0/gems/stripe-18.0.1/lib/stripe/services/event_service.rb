# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  class EventService < StripeService
    # List events, going back up to 30 days. Each event data is rendered according to Stripe API version at its creation time, specified in [event object](https://docs.stripe.com/api/events/object) api_version attribute (not according to your current Stripe API version or Stripe-Version header).
    def list(params = {}, opts = {})
      request(method: :get, path: "/v1/events", params: params, opts: opts, base_address: :api)
    end

    # Retrieves the details of an event if it was created in the last 30 days. Supply the unique identifier of the event, which you might have received in a webhook.
    def retrieve(id, params = {}, opts = {})
      request(
        method: :get,
        path: format("/v1/events/%<id>s", { id: CGI.escape(id) }),
        params: params,
        opts: opts,
        base_address: :api
      )
    end
  end
end
