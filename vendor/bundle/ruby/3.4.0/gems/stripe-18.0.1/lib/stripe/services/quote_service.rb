# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  class QuoteService < StripeService
    attr_reader :computed_upfront_line_items, :line_items

    def initialize(requestor)
      super
      @computed_upfront_line_items = Stripe::QuoteComputedUpfrontLineItemsService.new(@requestor)
      @line_items = Stripe::QuoteLineItemService.new(@requestor)
    end

    # Accepts the specified quote.
    def accept(quote, params = {}, opts = {})
      request(
        method: :post,
        path: format("/v1/quotes/%<quote>s/accept", { quote: CGI.escape(quote) }),
        params: params,
        opts: opts,
        base_address: :api
      )
    end

    # Cancels the quote.
    def cancel(quote, params = {}, opts = {})
      request(
        method: :post,
        path: format("/v1/quotes/%<quote>s/cancel", { quote: CGI.escape(quote) }),
        params: params,
        opts: opts,
        base_address: :api
      )
    end

    # A quote models prices and services for a customer. Default options for header, description, footer, and expires_at can be set in the dashboard via the [quote template](https://dashboard.stripe.com/settings/billing/quote).
    def create(params = {}, opts = {})
      request(method: :post, path: "/v1/quotes", params: params, opts: opts, base_address: :api)
    end

    # Finalizes the quote.
    def finalize_quote(quote, params = {}, opts = {})
      request(
        method: :post,
        path: format("/v1/quotes/%<quote>s/finalize", { quote: CGI.escape(quote) }),
        params: params,
        opts: opts,
        base_address: :api
      )
    end

    # Returns a list of your quotes.
    def list(params = {}, opts = {})
      request(method: :get, path: "/v1/quotes", params: params, opts: opts, base_address: :api)
    end

    # Download the PDF for a finalized quote. Explanation for special handling can be found [here](https://docs.stripe.com/quotes/overview#quote_pdf)
    def pdf(quote, params = {}, opts = {}, &read_body_chunk_block)
      opts = { api_base: APIRequestor.active_requestor.config.uploads_base }.merge(opts)
      request_stream(
        method: :get,
        path: format("/v1/quotes/%<quote>s/pdf", { quote: CGI.escape(quote) }),
        params: params,
        opts: opts,
        base_address: :files,
        &read_body_chunk_block
      )
    end

    # Retrieves the quote with the given ID.
    def retrieve(quote, params = {}, opts = {})
      request(
        method: :get,
        path: format("/v1/quotes/%<quote>s", { quote: CGI.escape(quote) }),
        params: params,
        opts: opts,
        base_address: :api
      )
    end

    # A quote models prices and services for a customer.
    def update(quote, params = {}, opts = {})
      request(
        method: :post,
        path: format("/v1/quotes/%<quote>s", { quote: CGI.escape(quote) }),
        params: params,
        opts: opts,
        base_address: :api
      )
    end
  end
end
