# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  module Treasury
    class TransactionListParams < ::Stripe::RequestParams
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

      class StatusTransitions < ::Stripe::RequestParams
        class PostedAt < ::Stripe::RequestParams
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
        # Returns Transactions with `posted_at` within the specified range.
        attr_accessor :posted_at

        def initialize(posted_at: nil)
          @posted_at = posted_at
        end
      end
      # Only return Transactions that were created during the given date interval.
      attr_accessor :created
      # A cursor for use in pagination. `ending_before` is an object ID that defines your place in the list. For instance, if you make a list request and receive 100 objects, starting with `obj_bar`, your subsequent call can include `ending_before=obj_bar` in order to fetch the previous page of the list.
      attr_accessor :ending_before
      # Specifies which fields in the response should be expanded.
      attr_accessor :expand
      # Returns objects associated with this FinancialAccount.
      attr_accessor :financial_account
      # A limit on the number of objects to be returned. Limit can range between 1 and 100, and the default is 10.
      attr_accessor :limit
      # The results are in reverse chronological order by `created` or `posted_at`. The default is `created`.
      attr_accessor :order_by
      # A cursor for use in pagination. `starting_after` is an object ID that defines your place in the list. For instance, if you make a list request and receive 100 objects, ending with `obj_foo`, your subsequent call can include `starting_after=obj_foo` in order to fetch the next page of the list.
      attr_accessor :starting_after
      # Only return Transactions that have the given status: `open`, `posted`, or `void`.
      attr_accessor :status
      # A filter for the `status_transitions.posted_at` timestamp. When using this filter, `status=posted` and `order_by=posted_at` must also be specified.
      attr_accessor :status_transitions

      def initialize(
        created: nil,
        ending_before: nil,
        expand: nil,
        financial_account: nil,
        limit: nil,
        order_by: nil,
        starting_after: nil,
        status: nil,
        status_transitions: nil
      )
        @created = created
        @ending_before = ending_before
        @expand = expand
        @financial_account = financial_account
        @limit = limit
        @order_by = order_by
        @starting_after = starting_after
        @status = status
        @status_transitions = status_transitions
      end
    end
  end
end
