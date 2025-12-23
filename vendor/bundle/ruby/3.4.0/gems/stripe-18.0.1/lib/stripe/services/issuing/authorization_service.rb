# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  module Issuing
    class AuthorizationService < StripeService
      # [Deprecated] Approves a pending Issuing Authorization object. This request should be made within the timeout window of the [real-time authorization](https://docs.stripe.com/docs/issuing/controls/real-time-authorizations) flow.
      # This method is deprecated. Instead, [respond directly to the webhook request to approve an authorization](https://docs.stripe.com/docs/issuing/controls/real-time-authorizations#authorization-handling).
      def approve(authorization, params = {}, opts = {})
        request(
          method: :post,
          path: format("/v1/issuing/authorizations/%<authorization>s/approve", { authorization: CGI.escape(authorization) }),
          params: params,
          opts: opts,
          base_address: :api
        )
      end

      # [Deprecated] Declines a pending Issuing Authorization object. This request should be made within the timeout window of the [real time authorization](https://docs.stripe.com/docs/issuing/controls/real-time-authorizations) flow.
      # This method is deprecated. Instead, [respond directly to the webhook request to decline an authorization](https://docs.stripe.com/docs/issuing/controls/real-time-authorizations#authorization-handling).
      def decline(authorization, params = {}, opts = {})
        request(
          method: :post,
          path: format("/v1/issuing/authorizations/%<authorization>s/decline", { authorization: CGI.escape(authorization) }),
          params: params,
          opts: opts,
          base_address: :api
        )
      end

      # Returns a list of Issuing Authorization objects. The objects are sorted in descending order by creation date, with the most recently created object appearing first.
      def list(params = {}, opts = {})
        request(
          method: :get,
          path: "/v1/issuing/authorizations",
          params: params,
          opts: opts,
          base_address: :api
        )
      end

      # Retrieves an Issuing Authorization object.
      def retrieve(authorization, params = {}, opts = {})
        request(
          method: :get,
          path: format("/v1/issuing/authorizations/%<authorization>s", { authorization: CGI.escape(authorization) }),
          params: params,
          opts: opts,
          base_address: :api
        )
      end

      # Updates the specified Issuing Authorization object by setting the values of the parameters passed. Any parameters not provided will be left unchanged.
      def update(authorization, params = {}, opts = {})
        request(
          method: :post,
          path: format("/v1/issuing/authorizations/%<authorization>s", { authorization: CGI.escape(authorization) }),
          params: params,
          opts: opts,
          base_address: :api
        )
      end
    end
  end
end
