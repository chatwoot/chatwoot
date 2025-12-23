# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  module Entitlements
    class ActiveEntitlementService < StripeService
      # Retrieve a list of active entitlements for a customer
      def list(params = {}, opts = {})
        request(
          method: :get,
          path: "/v1/entitlements/active_entitlements",
          params: params,
          opts: opts,
          base_address: :api
        )
      end

      # Retrieve an active entitlement
      def retrieve(id, params = {}, opts = {})
        request(
          method: :get,
          path: format("/v1/entitlements/active_entitlements/%<id>s", { id: CGI.escape(id) }),
          params: params,
          opts: opts,
          base_address: :api
        )
      end
    end
  end
end
