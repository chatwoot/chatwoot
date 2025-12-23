# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  class SubscriptionScheduleListParams < ::Stripe::RequestParams
    class CanceledAt < ::Stripe::RequestParams
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

    class CompletedAt < ::Stripe::RequestParams
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

    class ReleasedAt < ::Stripe::RequestParams
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
    # Only return subscription schedules that were created canceled the given date interval.
    attr_accessor :canceled_at
    # Only return subscription schedules that completed during the given date interval.
    attr_accessor :completed_at
    # Only return subscription schedules that were created during the given date interval.
    attr_accessor :created
    # Only return subscription schedules for the given customer.
    attr_accessor :customer
    # A cursor for use in pagination. `ending_before` is an object ID that defines your place in the list. For instance, if you make a list request and receive 100 objects, starting with `obj_bar`, your subsequent call can include `ending_before=obj_bar` in order to fetch the previous page of the list.
    attr_accessor :ending_before
    # Specifies which fields in the response should be expanded.
    attr_accessor :expand
    # A limit on the number of objects to be returned. Limit can range between 1 and 100, and the default is 10.
    attr_accessor :limit
    # Only return subscription schedules that were released during the given date interval.
    attr_accessor :released_at
    # Only return subscription schedules that have not started yet.
    attr_accessor :scheduled
    # A cursor for use in pagination. `starting_after` is an object ID that defines your place in the list. For instance, if you make a list request and receive 100 objects, ending with `obj_foo`, your subsequent call can include `starting_after=obj_foo` in order to fetch the next page of the list.
    attr_accessor :starting_after

    def initialize(
      canceled_at: nil,
      completed_at: nil,
      created: nil,
      customer: nil,
      ending_before: nil,
      expand: nil,
      limit: nil,
      released_at: nil,
      scheduled: nil,
      starting_after: nil
    )
      @canceled_at = canceled_at
      @completed_at = completed_at
      @created = created
      @customer = customer
      @ending_before = ending_before
      @expand = expand
      @limit = limit
      @released_at = released_at
      @scheduled = scheduled
      @starting_after = starting_after
    end
  end
end
