# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  class ApplePayDomainService < StripeService
    # Create an apple pay domain.
    def create(params = {}, opts = {})
      request(
        method: :post,
        path: "/v1/apple_pay/domains",
        params: params,
        opts: opts,
        base_address: :api
      )
    end

    # Delete an apple pay domain.
    def delete(domain, params = {}, opts = {})
      request(
        method: :delete,
        path: format("/v1/apple_pay/domains/%<domain>s", { domain: CGI.escape(domain) }),
        params: params,
        opts: opts,
        base_address: :api
      )
    end

    # List apple pay domains.
    def list(params = {}, opts = {})
      request(
        method: :get,
        path: "/v1/apple_pay/domains",
        params: params,
        opts: opts,
        base_address: :api
      )
    end

    # Retrieve an apple pay domain.
    def retrieve(domain, params = {}, opts = {})
      request(
        method: :get,
        path: format("/v1/apple_pay/domains/%<domain>s", { domain: CGI.escape(domain) }),
        params: params,
        opts: opts,
        base_address: :api
      )
    end
  end
end
