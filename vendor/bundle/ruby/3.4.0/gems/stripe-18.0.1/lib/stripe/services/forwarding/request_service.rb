# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  module Forwarding
    class RequestService < StripeService
      # Creates a ForwardingRequest object.
      def create(params = {}, opts = {})
        request(
          method: :post,
          path: "/v1/forwarding/requests",
          params: params,
          opts: opts,
          base_address: :api
        )
      end

      # Lists all ForwardingRequest objects.
      def list(params = {}, opts = {})
        request(
          method: :get,
          path: "/v1/forwarding/requests",
          params: params,
          opts: opts,
          base_address: :api
        )
      end

      # Retrieves a ForwardingRequest object.
      def retrieve(id, params = {}, opts = {})
        request(
          method: :get,
          path: format("/v1/forwarding/requests/%<id>s", { id: CGI.escape(id) }),
          params: params,
          opts: opts,
          base_address: :api
        )
      end
    end
  end
end
