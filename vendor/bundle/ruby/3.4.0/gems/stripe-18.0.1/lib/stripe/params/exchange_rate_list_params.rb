# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  class ExchangeRateListParams < ::Stripe::RequestParams
    # A cursor for use in pagination. `ending_before` is the currency that defines your place in the list. For instance, if you make a list request and receive 100 objects, starting with the exchange rate for currency X your subsequent call can include `ending_before=obj_bar` in order to fetch the previous page of the list.
    attr_accessor :ending_before
    # Specifies which fields in the response should be expanded.
    attr_accessor :expand
    # A limit on the number of objects to be returned. Limit can range between 1 and total number of supported payout currencies, and the default is the max.
    attr_accessor :limit
    # A cursor for use in pagination. `starting_after` is the currency that defines your place in the list. For instance, if you make a list request and receive 100 objects, ending with the exchange rate for currency X, your subsequent call can include `starting_after=X` in order to fetch the next page of the list.
    attr_accessor :starting_after

    def initialize(ending_before: nil, expand: nil, limit: nil, starting_after: nil)
      @ending_before = ending_before
      @expand = expand
      @limit = limit
      @starting_after = starting_after
    end
  end
end
