# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  class TaxRateListParams < ::Stripe::RequestParams
    class Created < ::Stripe::RequestParams
      # Minimum value to filter by (exclusive)
      attr_accessor :gt
      # Minimum value to filter by (inclusive)
      attr_accessor :gte
      # Maximum value to filter by (exclusive)
      attr_accessor :lt
      # Maximum value to filter by (inclusive)
      attr_accessor :lte

      def initialize(gt: nil, gte: nil, lt: nil, lte: nil)
        @gt = gt
        @gte = gte
        @lt = lt
        @lte = lte
      end
    end
    # Optional flag to filter by tax rates that are either active or inactive (archived).
    attr_accessor :active
    # Optional range for filtering created date.
    attr_accessor :created
    # A cursor for use in pagination. `ending_before` is an object ID that defines your place in the list. For instance, if you make a list request and receive 100 objects, starting with `obj_bar`, your subsequent call can include `ending_before=obj_bar` in order to fetch the previous page of the list.
    attr_accessor :ending_before
    # Specifies which fields in the response should be expanded.
    attr_accessor :expand
    # Optional flag to filter by tax rates that are inclusive (or those that are not inclusive).
    attr_accessor :inclusive
    # A limit on the number of objects to be returned. Limit can range between 1 and 100, and the default is 10.
    attr_accessor :limit
    # A cursor for use in pagination. `starting_after` is an object ID that defines your place in the list. For instance, if you make a list request and receive 100 objects, ending with `obj_foo`, your subsequent call can include `starting_after=obj_foo` in order to fetch the next page of the list.
    attr_accessor :starting_after

    def initialize(
      active: nil,
      created: nil,
      ending_before: nil,
      expand: nil,
      inclusive: nil,
      limit: nil,
      starting_after: nil
    )
      @active = active
      @created = created
      @ending_before = ending_before
      @expand = expand
      @inclusive = inclusive
      @limit = limit
      @starting_after = starting_after
    end
  end
end
