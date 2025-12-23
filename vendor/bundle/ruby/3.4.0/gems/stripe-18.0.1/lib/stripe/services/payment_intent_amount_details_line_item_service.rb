# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  class PaymentIntentAmountDetailsLineItemService < StripeService
    # Lists all LineItems of a given PaymentIntent.
    def list(intent, params = {}, opts = {})
      request(
        method: :get,
        path: format("/v1/payment_intents/%<intent>s/amount_details_line_items", { intent: CGI.escape(intent) }),
        params: params,
        opts: opts,
        base_address: :api
      )
    end
  end
end
