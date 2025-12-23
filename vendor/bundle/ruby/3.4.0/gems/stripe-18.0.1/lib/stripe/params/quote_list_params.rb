# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  class QuoteListParams < ::Stripe::RequestParams
    # The ID of the customer whose quotes will be retrieved.
    attr_accessor :customer
    # A cursor for use in pagination. `ending_before` is an object ID that defines your place in the list. For instance, if you make a list request and receive 100 objects, starting with `obj_bar`, your subsequent call can include `ending_before=obj_bar` in order to fetch the previous page of the list.
    attr_accessor :ending_before
    # Specifies which fields in the response should be expanded.
    attr_accessor :expand
    # A limit on the number of objects to be returned. Limit can range between 1 and 100, and the default is 10.
    attr_accessor :limit
    # A cursor for use in pagination. `starting_after` is an object ID that defines your place in the list. For instance, if you make a list request and receive 100 objects, ending with `obj_foo`, your subsequent call can include `starting_after=obj_foo` in order to fetch the next page of the list.
    attr_accessor :starting_after
    # The status of the quote.
    attr_accessor :status
    # Provides a list of quotes that are associated with the specified test clock. The response will not include quotes with test clocks if this and the customer parameter is not set.
    attr_accessor :test_clock

    def initialize(
      customer: nil,
      ending_before: nil,
      expand: nil,
      limit: nil,
      starting_after: nil,
      status: nil,
      test_clock: nil
    )
      @customer = customer
      @ending_before = ending_before
      @expand = expand
      @limit = limit
      @starting_after = starting_after
      @status = status
      @test_clock = test_clock
    end
  end
end
