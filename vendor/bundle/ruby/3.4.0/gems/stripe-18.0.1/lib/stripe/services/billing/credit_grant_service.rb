# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  module Billing
    class CreditGrantService < StripeService
      # Creates a credit grant.
      def create(params = {}, opts = {})
        request(
          method: :post,
          path: "/v1/billing/credit_grants",
          params: params,
          opts: opts,
          base_address: :api
        )
      end

      # Expires a credit grant.
      def expire(id, params = {}, opts = {})
        request(
          method: :post,
          path: format("/v1/billing/credit_grants/%<id>s/expire", { id: CGI.escape(id) }),
          params: params,
          opts: opts,
          base_address: :api
        )
      end

      # Retrieve a list of credit grants.
      def list(params = {}, opts = {})
        request(
          method: :get,
          path: "/v1/billing/credit_grants",
          params: params,
          opts: opts,
          base_address: :api
        )
      end

      # Retrieves a credit grant.
      def retrieve(id, params = {}, opts = {})
        request(
          method: :get,
          path: format("/v1/billing/credit_grants/%<id>s", { id: CGI.escape(id) }),
          params: params,
          opts: opts,
          base_address: :api
        )
      end

      # Updates a credit grant.
      def update(id, params = {}, opts = {})
        request(
          method: :post,
          path: format("/v1/billing/credit_grants/%<id>s", { id: CGI.escape(id) }),
          params: params,
          opts: opts,
          base_address: :api
        )
      end

      # Voids a credit grant.
      def void_grant(id, params = {}, opts = {})
        request(
          method: :post,
          path: format("/v1/billing/credit_grants/%<id>s/void", { id: CGI.escape(id) }),
          params: params,
          opts: opts,
          base_address: :api
        )
      end
    end
  end
end
