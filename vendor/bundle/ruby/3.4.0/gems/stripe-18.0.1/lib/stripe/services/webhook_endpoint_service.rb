# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  class WebhookEndpointService < StripeService
    # A webhook endpoint must have a url and a list of enabled_events. You may optionally specify the Boolean connect parameter. If set to true, then a Connect webhook endpoint that notifies the specified url about events from all connected accounts is created; otherwise an account webhook endpoint that notifies the specified url only about events from your account is created. You can also create webhook endpoints in the [webhooks settings](https://dashboard.stripe.com/account/webhooks) section of the Dashboard.
    def create(params = {}, opts = {})
      request(
        method: :post,
        path: "/v1/webhook_endpoints",
        params: params,
        opts: opts,
        base_address: :api
      )
    end

    # You can also delete webhook endpoints via the [webhook endpoint management](https://dashboard.stripe.com/account/webhooks) page of the Stripe dashboard.
    def delete(webhook_endpoint, params = {}, opts = {})
      request(
        method: :delete,
        path: format("/v1/webhook_endpoints/%<webhook_endpoint>s", { webhook_endpoint: CGI.escape(webhook_endpoint) }),
        params: params,
        opts: opts,
        base_address: :api
      )
    end

    # Returns a list of your webhook endpoints.
    def list(params = {}, opts = {})
      request(
        method: :get,
        path: "/v1/webhook_endpoints",
        params: params,
        opts: opts,
        base_address: :api
      )
    end

    # Retrieves the webhook endpoint with the given ID.
    def retrieve(webhook_endpoint, params = {}, opts = {})
      request(
        method: :get,
        path: format("/v1/webhook_endpoints/%<webhook_endpoint>s", { webhook_endpoint: CGI.escape(webhook_endpoint) }),
        params: params,
        opts: opts,
        base_address: :api
      )
    end

    # Updates the webhook endpoint. You may edit the url, the list of enabled_events, and the status of your endpoint.
    def update(webhook_endpoint, params = {}, opts = {})
      request(
        method: :post,
        path: format("/v1/webhook_endpoints/%<webhook_endpoint>s", { webhook_endpoint: CGI.escape(webhook_endpoint) }),
        params: params,
        opts: opts,
        base_address: :api
      )
    end
  end
end
