# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  class ProductListParams < ::Stripe::RequestParams
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
    # Only return products that are active or inactive (e.g., pass `false` to list all inactive products).
    attr_accessor :active
    # Only return products that were created during the given date interval.
    attr_accessor :created
    # A cursor for use in pagination. `ending_before` is an object ID that defines your place in the list. For instance, if you make a list request and receive 100 objects, starting with `obj_bar`, your subsequent call can include `ending_before=obj_bar` in order to fetch the previous page of the list.
    attr_accessor :ending_before
    # Specifies which fields in the response should be expanded.
    attr_accessor :expand
    # Only return products with the given IDs. Cannot be used with [starting_after](https://stripe.com/docs/api#list_products-starting_after) or [ending_before](https://stripe.com/docs/api#list_products-ending_before).
    attr_accessor :ids
    # A limit on the number of objects to be returned. Limit can range between 1 and 100, and the default is 10.
    attr_accessor :limit
    # Only return products that can be shipped (i.e., physical, not digital products).
    attr_accessor :shippable
    # A cursor for use in pagination. `starting_after` is an object ID that defines your place in the list. For instance, if you make a list request and receive 100 objects, ending with `obj_foo`, your subsequent call can include `starting_after=obj_foo` in order to fetch the next page of the list.
    attr_accessor :starting_after
    # Only return products of this type.
    attr_accessor :type
    # Only return products with the given url.
    attr_accessor :url

    def initialize(
      active: nil,
      created: nil,
      ending_before: nil,
      expand: nil,
      ids: nil,
      limit: nil,
      shippable: nil,
      starting_after: nil,
      type: nil,
      url: nil
    )
      @active = active
      @created = created
      @ending_before = ending_before
      @expand = expand
      @ids = ids
      @limit = limit
      @shippable = shippable
      @starting_after = starting_after
      @type = type
      @url = url
    end
  end
end
