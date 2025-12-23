# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  class InvoiceSearchParams < ::Stripe::RequestParams
    # Specifies which fields in the response should be expanded.
    attr_accessor :expand
    # A limit on the number of objects to be returned. Limit can range between 1 and 100, and the default is 10.
    attr_accessor :limit
    # A cursor for pagination across multiple pages of results. Don't include this parameter on the first call. Use the next_page value returned in a previous response to request subsequent results.
    attr_accessor :page
    # The search query string. See [search query language](https://stripe.com/docs/search#search-query-language) and the list of supported [query fields for invoices](https://stripe.com/docs/search#query-fields-for-invoices).
    attr_accessor :query

    def initialize(expand: nil, limit: nil, page: nil, query: nil)
      @expand = expand
      @limit = limit
      @page = page
      @query = query
    end
  end
end
