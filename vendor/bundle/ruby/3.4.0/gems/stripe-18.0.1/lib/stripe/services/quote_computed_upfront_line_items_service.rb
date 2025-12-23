# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  class QuoteComputedUpfrontLineItemsService < StripeService
    # When retrieving a quote, there is an includable [computed.upfront.line_items](https://stripe.com/docs/api/quotes/object#quote_object-computed-upfront-line_items) property containing the first handful of those items. There is also a URL where you can retrieve the full (paginated) list of upfront line items.
    def list(quote, params = {}, opts = {})
      request(
        method: :get,
        path: format("/v1/quotes/%<quote>s/computed_upfront_line_items", { quote: CGI.escape(quote) }),
        params: params,
        opts: opts,
        base_address: :api
      )
    end
  end
end
