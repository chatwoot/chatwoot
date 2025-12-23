# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  class ChargeListParams < ::Stripe::RequestParams
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
    # Only return charges that were created during the given date interval.
    attr_accessor :created
    # Only return charges for the customer specified by this customer ID.
    attr_accessor :customer
    # A cursor for use in pagination. `ending_before` is an object ID that defines your place in the list. For instance, if you make a list request and receive 100 objects, starting with `obj_bar`, your subsequent call can include `ending_before=obj_bar` in order to fetch the previous page of the list.
    attr_accessor :ending_before
    # Specifies which fields in the response should be expanded.
    attr_accessor :expand
    # A limit on the number of objects to be returned. Limit can range between 1 and 100, and the default is 10.
    attr_accessor :limit
    # Only return charges that were created by the PaymentIntent specified by this PaymentIntent ID.
    attr_accessor :payment_intent
    # A cursor for use in pagination. `starting_after` is an object ID that defines your place in the list. For instance, if you make a list request and receive 100 objects, ending with `obj_foo`, your subsequent call can include `starting_after=obj_foo` in order to fetch the next page of the list.
    attr_accessor :starting_after
    # Only return charges for this transfer group, limited to 100.
    attr_accessor :transfer_group

    def initialize(
      created: nil,
      customer: nil,
      ending_before: nil,
      expand: nil,
      limit: nil,
      payment_intent: nil,
      starting_after: nil,
      transfer_group: nil
    )
      @created = created
      @customer = customer
      @ending_before = ending_before
      @expand = expand
      @limit = limit
      @payment_intent = payment_intent
      @starting_after = starting_after
      @transfer_group = transfer_group
    end
  end
end
