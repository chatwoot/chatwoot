# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  module Checkout
    class SessionService < StripeService
      attr_reader :line_items

      def initialize(requestor)
        super
        @line_items = Stripe::Checkout::SessionLineItemService.new(@requestor)
      end

      # Creates a Checkout Session object.
      def create(params = {}, opts = {})
        request(
          method: :post,
          path: "/v1/checkout/sessions",
          params: params,
          opts: opts,
          base_address: :api
        )
      end

      # A Checkout Session can be expired when it is in one of these statuses: open
      #
      # After it expires, a customer can't complete a Checkout Session and customers loading the Checkout Session see a message saying the Checkout Session is expired.
      def expire(session, params = {}, opts = {})
        request(
          method: :post,
          path: format("/v1/checkout/sessions/%<session>s/expire", { session: CGI.escape(session) }),
          params: params,
          opts: opts,
          base_address: :api
        )
      end

      # Returns a list of Checkout Sessions.
      def list(params = {}, opts = {})
        request(
          method: :get,
          path: "/v1/checkout/sessions",
          params: params,
          opts: opts,
          base_address: :api
        )
      end

      # Retrieves a Checkout Session object.
      def retrieve(session, params = {}, opts = {})
        request(
          method: :get,
          path: format("/v1/checkout/sessions/%<session>s", { session: CGI.escape(session) }),
          params: params,
          opts: opts,
          base_address: :api
        )
      end

      # Updates a Checkout Session object.
      #
      # Related guide: [Dynamically update Checkout](https://docs.stripe.com/payments/checkout/dynamic-updates)
      def update(session, params = {}, opts = {})
        request(
          method: :post,
          path: format("/v1/checkout/sessions/%<session>s", { session: CGI.escape(session) }),
          params: params,
          opts: opts,
          base_address: :api
        )
      end
    end
  end
end
