# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  class TaxIdListParams < ::Stripe::RequestParams
    class Owner < ::Stripe::RequestParams
      # Account the tax ID belongs to. Required when `type=account`
      attr_accessor :account
      # Customer the tax ID belongs to. Required when `type=customer`
      attr_accessor :customer
      # Type of owner referenced.
      attr_accessor :type

      def initialize(account: nil, customer: nil, type: nil)
        @account = account
        @customer = customer
        @type = type
      end
    end
    # A cursor for use in pagination. `ending_before` is an object ID that defines your place in the list. For instance, if you make a list request and receive 100 objects, starting with `obj_bar`, your subsequent call can include `ending_before=obj_bar` in order to fetch the previous page of the list.
    attr_accessor :ending_before
    # Specifies which fields in the response should be expanded.
    attr_accessor :expand
    # A limit on the number of objects to be returned. Limit can range between 1 and 100, and the default is 10.
    attr_accessor :limit
    # The account or customer the tax ID belongs to. Defaults to `owner[type]=self`.
    attr_accessor :owner
    # A cursor for use in pagination. `starting_after` is an object ID that defines your place in the list. For instance, if you make a list request and receive 100 objects, ending with `obj_foo`, your subsequent call can include `starting_after=obj_foo` in order to fetch the next page of the list.
    attr_accessor :starting_after

    def initialize(ending_before: nil, expand: nil, limit: nil, owner: nil, starting_after: nil)
      @ending_before = ending_before
      @expand = expand
      @limit = limit
      @owner = owner
      @starting_after = starting_after
    end
  end
end
