# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  module FinancialConnections
    class TransactionListParams < ::Stripe::RequestParams
      class TransactedAt < ::Stripe::RequestParams
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

      class TransactionRefresh < ::Stripe::RequestParams
        # Return results where the transactions were created or updated by a refresh that took place after this refresh (non-inclusive).
        attr_accessor :after

        def initialize(after: nil)
          @after = after
        end
      end
      # The ID of the Financial Connections Account whose transactions will be retrieved.
      attr_accessor :account
      # A cursor for use in pagination. `ending_before` is an object ID that defines your place in the list. For instance, if you make a list request and receive 100 objects, starting with `obj_bar`, your subsequent call can include `ending_before=obj_bar` in order to fetch the previous page of the list.
      attr_accessor :ending_before
      # Specifies which fields in the response should be expanded.
      attr_accessor :expand
      # A limit on the number of objects to be returned. Limit can range between 1 and 100, and the default is 10.
      attr_accessor :limit
      # A cursor for use in pagination. `starting_after` is an object ID that defines your place in the list. For instance, if you make a list request and receive 100 objects, ending with `obj_foo`, your subsequent call can include `starting_after=obj_foo` in order to fetch the next page of the list.
      attr_accessor :starting_after
      # A filter on the list based on the object `transacted_at` field. The value can be a string with an integer Unix timestamp, or it can be a dictionary with the following options:
      attr_accessor :transacted_at
      # A filter on the list based on the object `transaction_refresh` field. The value can be a dictionary with the following options:
      attr_accessor :transaction_refresh

      def initialize(
        account: nil,
        ending_before: nil,
        expand: nil,
        limit: nil,
        starting_after: nil,
        transacted_at: nil,
        transaction_refresh: nil
      )
        @account = account
        @ending_before = ending_before
        @expand = expand
        @limit = limit
        @starting_after = starting_after
        @transacted_at = transacted_at
        @transaction_refresh = transaction_refresh
      end
    end
  end
end
