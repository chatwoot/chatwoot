# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  class InvoiceListParams < ::Stripe::RequestParams
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

    class DueDate < ::Stripe::RequestParams
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
    # The collection method of the invoice to retrieve. Either `charge_automatically` or `send_invoice`.
    attr_accessor :collection_method
    # Only return invoices that were created during the given date interval.
    attr_accessor :created
    # Only return invoices for the customer specified by this customer ID.
    attr_accessor :customer
    # Attribute for param field due_date
    attr_accessor :due_date
    # A cursor for use in pagination. `ending_before` is an object ID that defines your place in the list. For instance, if you make a list request and receive 100 objects, starting with `obj_bar`, your subsequent call can include `ending_before=obj_bar` in order to fetch the previous page of the list.
    attr_accessor :ending_before
    # Specifies which fields in the response should be expanded.
    attr_accessor :expand
    # A limit on the number of objects to be returned. Limit can range between 1 and 100, and the default is 10.
    attr_accessor :limit
    # A cursor for use in pagination. `starting_after` is an object ID that defines your place in the list. For instance, if you make a list request and receive 100 objects, ending with `obj_foo`, your subsequent call can include `starting_after=obj_foo` in order to fetch the next page of the list.
    attr_accessor :starting_after
    # The status of the invoice, one of `draft`, `open`, `paid`, `uncollectible`, or `void`. [Learn more](https://stripe.com/docs/billing/invoices/workflow#workflow-overview)
    attr_accessor :status
    # Only return invoices for the subscription specified by this subscription ID.
    attr_accessor :subscription

    def initialize(
      collection_method: nil,
      created: nil,
      customer: nil,
      due_date: nil,
      ending_before: nil,
      expand: nil,
      limit: nil,
      starting_after: nil,
      status: nil,
      subscription: nil
    )
      @collection_method = collection_method
      @created = created
      @customer = customer
      @due_date = due_date
      @ending_before = ending_before
      @expand = expand
      @limit = limit
      @starting_after = starting_after
      @status = status
      @subscription = subscription
    end
  end
end
