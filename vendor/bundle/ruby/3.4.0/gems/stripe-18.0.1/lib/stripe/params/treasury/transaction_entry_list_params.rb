# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  module Treasury
    class TransactionEntryListParams < ::Stripe::RequestParams
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

      class EffectiveAt < ::Stripe::RequestParams
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
      # Only return TransactionEntries that were created during the given date interval.
      attr_accessor :created
      # Attribute for param field effective_at
      attr_accessor :effective_at
      # A cursor for use in pagination. `ending_before` is an object ID that defines your place in the list. For instance, if you make a list request and receive 100 objects, starting with `obj_bar`, your subsequent call can include `ending_before=obj_bar` in order to fetch the previous page of the list.
      attr_accessor :ending_before
      # Specifies which fields in the response should be expanded.
      attr_accessor :expand
      # Returns objects associated with this FinancialAccount.
      attr_accessor :financial_account
      # A limit on the number of objects to be returned. Limit can range between 1 and 100, and the default is 10.
      attr_accessor :limit
      # The results are in reverse chronological order by `created` or `effective_at`. The default is `created`.
      attr_accessor :order_by
      # A cursor for use in pagination. `starting_after` is an object ID that defines your place in the list. For instance, if you make a list request and receive 100 objects, ending with `obj_foo`, your subsequent call can include `starting_after=obj_foo` in order to fetch the next page of the list.
      attr_accessor :starting_after
      # Only return TransactionEntries associated with this Transaction.
      attr_accessor :transaction

      def initialize(
        created: nil,
        effective_at: nil,
        ending_before: nil,
        expand: nil,
        financial_account: nil,
        limit: nil,
        order_by: nil,
        starting_after: nil,
        transaction: nil
      )
        @created = created
        @effective_at = effective_at
        @ending_before = ending_before
        @expand = expand
        @financial_account = financial_account
        @limit = limit
        @order_by = order_by
        @starting_after = starting_after
        @transaction = transaction
      end
    end
  end
end
