# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  class PaymentLinkService < StripeService
    attr_reader :line_items

    def initialize(requestor)
      super
      @line_items = Stripe::PaymentLinkLineItemService.new(@requestor)
    end

    # Creates a payment link.
    def create(params = {}, opts = {})
      request(
        method: :post,
        path: "/v1/payment_links",
        params: params,
        opts: opts,
        base_address: :api
      )
    end

    # Returns a list of your payment links.
    def list(params = {}, opts = {})
      request(
        method: :get,
        path: "/v1/payment_links",
        params: params,
        opts: opts,
        base_address: :api
      )
    end

    # Retrieve a payment link.
    def retrieve(payment_link, params = {}, opts = {})
      request(
        method: :get,
        path: format("/v1/payment_links/%<payment_link>s", { payment_link: CGI.escape(payment_link) }),
        params: params,
        opts: opts,
        base_address: :api
      )
    end

    # Updates a payment link.
    def update(payment_link, params = {}, opts = {})
      request(
        method: :post,
        path: format("/v1/payment_links/%<payment_link>s", { payment_link: CGI.escape(payment_link) }),
        params: params,
        opts: opts,
        base_address: :api
      )
    end
  end
end
