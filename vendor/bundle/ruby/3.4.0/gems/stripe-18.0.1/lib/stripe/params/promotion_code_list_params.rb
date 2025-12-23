# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  class PromotionCodeListParams < ::Stripe::RequestParams
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
    # Filter promotion codes by whether they are active.
    attr_accessor :active
    # Only return promotion codes that have this case-insensitive code.
    attr_accessor :code
    # Only return promotion codes for this coupon.
    attr_accessor :coupon
    # A filter on the list, based on the object `created` field. The value can be a string with an integer Unix timestamp, or it can be a dictionary with a number of different query options.
    attr_accessor :created
    # Only return promotion codes that are restricted to this customer.
    attr_accessor :customer
    # A cursor for use in pagination. `ending_before` is an object ID that defines your place in the list. For instance, if you make a list request and receive 100 objects, starting with `obj_bar`, your subsequent call can include `ending_before=obj_bar` in order to fetch the previous page of the list.
    attr_accessor :ending_before
    # Specifies which fields in the response should be expanded.
    attr_accessor :expand
    # A limit on the number of objects to be returned. Limit can range between 1 and 100, and the default is 10.
    attr_accessor :limit
    # A cursor for use in pagination. `starting_after` is an object ID that defines your place in the list. For instance, if you make a list request and receive 100 objects, ending with `obj_foo`, your subsequent call can include `starting_after=obj_foo` in order to fetch the next page of the list.
    attr_accessor :starting_after

    def initialize(
      active: nil,
      code: nil,
      coupon: nil,
      created: nil,
      customer: nil,
      ending_before: nil,
      expand: nil,
      limit: nil,
      starting_after: nil
    )
      @active = active
      @code = code
      @coupon = coupon
      @created = created
      @customer = customer
      @ending_before = ending_before
      @expand = expand
      @limit = limit
      @starting_after = starting_after
    end
  end
end
