# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  class InvoicePaymentListParams < ::Stripe::RequestParams
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

    class Payment < ::Stripe::RequestParams
      # Only return invoice payments associated by this payment intent ID.
      attr_accessor :payment_intent
      # Only return invoice payments associated by this payment record ID.
      attr_accessor :payment_record
      # Only return invoice payments associated by this payment type.
      attr_accessor :type

      def initialize(payment_intent: nil, payment_record: nil, type: nil)
        @payment_intent = payment_intent
        @payment_record = payment_record
        @type = type
      end
    end
    # Only return invoice payments that were created during the given date interval.
    attr_accessor :created
    # A cursor for use in pagination. `ending_before` is an object ID that defines your place in the list. For instance, if you make a list request and receive 100 objects, starting with `obj_bar`, your subsequent call can include `ending_before=obj_bar` in order to fetch the previous page of the list.
    attr_accessor :ending_before
    # Specifies which fields in the response should be expanded.
    attr_accessor :expand
    # The identifier of the invoice whose payments to return.
    attr_accessor :invoice
    # A limit on the number of objects to be returned. Limit can range between 1 and 100, and the default is 10.
    attr_accessor :limit
    # The payment details of the invoice payments to return.
    attr_accessor :payment
    # A cursor for use in pagination. `starting_after` is an object ID that defines your place in the list. For instance, if you make a list request and receive 100 objects, ending with `obj_foo`, your subsequent call can include `starting_after=obj_foo` in order to fetch the next page of the list.
    attr_accessor :starting_after
    # The status of the invoice payments to return.
    attr_accessor :status

    def initialize(
      created: nil,
      ending_before: nil,
      expand: nil,
      invoice: nil,
      limit: nil,
      payment: nil,
      starting_after: nil,
      status: nil
    )
      @created = created
      @ending_before = ending_before
      @expand = expand
      @invoice = invoice
      @limit = limit
      @payment = payment
      @starting_after = starting_after
      @status = status
    end
  end
end
