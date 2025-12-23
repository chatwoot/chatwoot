# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  class EventListParams < ::Stripe::RequestParams
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
    # Only return events that were created during the given date interval.
    attr_accessor :created
    # Filter events by whether all webhooks were successfully delivered. If false, events which are still pending or have failed all delivery attempts to a webhook endpoint will be returned.
    attr_accessor :delivery_success
    # A cursor for use in pagination. `ending_before` is an object ID that defines your place in the list. For instance, if you make a list request and receive 100 objects, starting with `obj_bar`, your subsequent call can include `ending_before=obj_bar` in order to fetch the previous page of the list.
    attr_accessor :ending_before
    # Specifies which fields in the response should be expanded.
    attr_accessor :expand
    # A limit on the number of objects to be returned. Limit can range between 1 and 100, and the default is 10.
    attr_accessor :limit
    # A cursor for use in pagination. `starting_after` is an object ID that defines your place in the list. For instance, if you make a list request and receive 100 objects, ending with `obj_foo`, your subsequent call can include `starting_after=obj_foo` in order to fetch the next page of the list.
    attr_accessor :starting_after
    # A string containing a specific event name, or group of events using * as a wildcard. The list will be filtered to include only events with a matching event property.
    attr_accessor :type
    # An array of up to 20 strings containing specific event names. The list will be filtered to include only events with a matching event property. You may pass either `type` or `types`, but not both.
    attr_accessor :types

    def initialize(
      created: nil,
      delivery_success: nil,
      ending_before: nil,
      expand: nil,
      limit: nil,
      starting_after: nil,
      type: nil,
      types: nil
    )
      @created = created
      @delivery_success = delivery_success
      @ending_before = ending_before
      @expand = expand
      @limit = limit
      @starting_after = starting_after
      @type = type
      @types = types
    end
  end
end
