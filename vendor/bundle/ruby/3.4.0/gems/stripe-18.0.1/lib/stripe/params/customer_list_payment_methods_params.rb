# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  class CustomerListPaymentMethodsParams < ::Stripe::RequestParams
    # This field indicates whether this payment method can be shown again to its customer in a checkout flow. Stripe products such as Checkout and Elements use this field to determine whether a payment method can be shown as a saved payment method in a checkout flow.
    attr_accessor :allow_redisplay
    # A cursor for use in pagination. `ending_before` is an object ID that defines your place in the list. For instance, if you make a list request and receive 100 objects, starting with `obj_bar`, your subsequent call can include `ending_before=obj_bar` in order to fetch the previous page of the list.
    attr_accessor :ending_before
    # Specifies which fields in the response should be expanded.
    attr_accessor :expand
    # A limit on the number of objects to be returned. Limit can range between 1 and 100, and the default is 10.
    attr_accessor :limit
    # A cursor for use in pagination. `starting_after` is an object ID that defines your place in the list. For instance, if you make a list request and receive 100 objects, ending with `obj_foo`, your subsequent call can include `starting_after=obj_foo` in order to fetch the next page of the list.
    attr_accessor :starting_after
    # An optional filter on the list, based on the object `type` field. Without the filter, the list includes all current and future payment method types. If your integration expects only one type of payment method in the response, make sure to provide a type value in the request.
    attr_accessor :type

    def initialize(
      allow_redisplay: nil,
      ending_before: nil,
      expand: nil,
      limit: nil,
      starting_after: nil,
      type: nil
    )
      @allow_redisplay = allow_redisplay
      @ending_before = ending_before
      @expand = expand
      @limit = limit
      @starting_after = starting_after
      @type = type
    end
  end
end
