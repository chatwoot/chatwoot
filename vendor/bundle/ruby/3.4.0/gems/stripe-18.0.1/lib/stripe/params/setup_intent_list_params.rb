# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  class SetupIntentListParams < ::Stripe::RequestParams
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
    # If present, the SetupIntent's payment method will be attached to the in-context Stripe Account.
    #
    # It can only be used for this Stripe Account’s own money movement flows like InboundTransfer and OutboundTransfers. It cannot be set to true when setting up a PaymentMethod for a Customer, and defaults to false when attaching a PaymentMethod to a Customer.
    attr_accessor :attach_to_self
    # A filter on the list, based on the object `created` field. The value can be a string with an integer Unix timestamp, or it can be a dictionary with a number of different query options.
    attr_accessor :created
    # Only return SetupIntents for the customer specified by this customer ID.
    attr_accessor :customer
    # A cursor for use in pagination. `ending_before` is an object ID that defines your place in the list. For instance, if you make a list request and receive 100 objects, starting with `obj_bar`, your subsequent call can include `ending_before=obj_bar` in order to fetch the previous page of the list.
    attr_accessor :ending_before
    # Specifies which fields in the response should be expanded.
    attr_accessor :expand
    # A limit on the number of objects to be returned. Limit can range between 1 and 100, and the default is 10.
    attr_accessor :limit
    # Only return SetupIntents that associate with the specified payment method.
    attr_accessor :payment_method
    # A cursor for use in pagination. `starting_after` is an object ID that defines your place in the list. For instance, if you make a list request and receive 100 objects, ending with `obj_foo`, your subsequent call can include `starting_after=obj_foo` in order to fetch the next page of the list.
    attr_accessor :starting_after

    def initialize(
      attach_to_self: nil,
      created: nil,
      customer: nil,
      ending_before: nil,
      expand: nil,
      limit: nil,
      payment_method: nil,
      starting_after: nil
    )
      @attach_to_self = attach_to_self
      @created = created
      @customer = customer
      @ending_before = ending_before
      @expand = expand
      @limit = limit
      @payment_method = payment_method
      @starting_after = starting_after
    end
  end
end
