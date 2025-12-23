# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  class SourceTransactionService < StripeService
    # List source transactions for a given source.
    def list(source, params = {}, opts = {})
      request(
        method: :get,
        path: format("/v1/sources/%<source>s/source_transactions", { source: CGI.escape(source) }),
        params: params,
        opts: opts,
        base_address: :api
      )
    end
  end
end
