# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  class PriceListParams < ::Stripe::RequestParams
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

    class Recurring < ::Stripe::RequestParams
      # Filter by billing frequency. Either `day`, `week`, `month` or `year`.
      attr_accessor :interval
      # Filter by the price's meter.
      attr_accessor :meter
      # Filter by the usage type for this price. Can be either `metered` or `licensed`.
      attr_accessor :usage_type

      def initialize(interval: nil, meter: nil, usage_type: nil)
        @interval = interval
        @meter = meter
        @usage_type = usage_type
      end
    end
    # Only return prices that are active or inactive (e.g., pass `false` to list all inactive prices).
    attr_accessor :active
    # A filter on the list, based on the object `created` field. The value can be a string with an integer Unix timestamp, or it can be a dictionary with a number of different query options.
    attr_accessor :created
    # Only return prices for the given currency.
    attr_accessor :currency
    # A cursor for use in pagination. `ending_before` is an object ID that defines your place in the list. For instance, if you make a list request and receive 100 objects, starting with `obj_bar`, your subsequent call can include `ending_before=obj_bar` in order to fetch the previous page of the list.
    attr_accessor :ending_before
    # Specifies which fields in the response should be expanded.
    attr_accessor :expand
    # A limit on the number of objects to be returned. Limit can range between 1 and 100, and the default is 10.
    attr_accessor :limit
    # Only return the price with these lookup_keys, if any exist. You can specify up to 10 lookup_keys.
    attr_accessor :lookup_keys
    # Only return prices for the given product.
    attr_accessor :product
    # Only return prices with these recurring fields.
    attr_accessor :recurring
    # A cursor for use in pagination. `starting_after` is an object ID that defines your place in the list. For instance, if you make a list request and receive 100 objects, ending with `obj_foo`, your subsequent call can include `starting_after=obj_foo` in order to fetch the next page of the list.
    attr_accessor :starting_after
    # Only return prices of type `recurring` or `one_time`.
    attr_accessor :type

    def initialize(
      active: nil,
      created: nil,
      currency: nil,
      ending_before: nil,
      expand: nil,
      limit: nil,
      lookup_keys: nil,
      product: nil,
      recurring: nil,
      starting_after: nil,
      type: nil
    )
      @active = active
      @created = created
      @currency = currency
      @ending_before = ending_before
      @expand = expand
      @limit = limit
      @lookup_keys = lookup_keys
      @product = product
      @recurring = recurring
      @starting_after = starting_after
      @type = type
    end
  end
end
