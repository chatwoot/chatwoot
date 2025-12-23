# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  module Billing
    class AlertService < StripeService
      # Reactivates this alert, allowing it to trigger again.
      def activate(id, params = {}, opts = {})
        request(
          method: :post,
          path: format("/v1/billing/alerts/%<id>s/activate", { id: CGI.escape(id) }),
          params: params,
          opts: opts,
          base_address: :api
        )
      end

      # Archives this alert, removing it from the list view and APIs. This is non-reversible.
      def archive(id, params = {}, opts = {})
        request(
          method: :post,
          path: format("/v1/billing/alerts/%<id>s/archive", { id: CGI.escape(id) }),
          params: params,
          opts: opts,
          base_address: :api
        )
      end

      # Creates a billing alert
      def create(params = {}, opts = {})
        request(
          method: :post,
          path: "/v1/billing/alerts",
          params: params,
          opts: opts,
          base_address: :api
        )
      end

      # Deactivates this alert, preventing it from triggering.
      def deactivate(id, params = {}, opts = {})
        request(
          method: :post,
          path: format("/v1/billing/alerts/%<id>s/deactivate", { id: CGI.escape(id) }),
          params: params,
          opts: opts,
          base_address: :api
        )
      end

      # Lists billing active and inactive alerts
      def list(params = {}, opts = {})
        request(
          method: :get,
          path: "/v1/billing/alerts",
          params: params,
          opts: opts,
          base_address: :api
        )
      end

      # Retrieves a billing alert given an ID
      def retrieve(id, params = {}, opts = {})
        request(
          method: :get,
          path: format("/v1/billing/alerts/%<id>s", { id: CGI.escape(id) }),
          params: params,
          opts: opts,
          base_address: :api
        )
      end
    end
  end
end
