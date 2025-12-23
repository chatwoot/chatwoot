# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  module Forwarding
    class RequestListParams < ::Stripe::RequestParams
      class Created < ::Stripe::RequestParams
        # Return results where the `created` field is greater than this value.
        attr_accessor :gt
        # Return results where the `created` field is greater than or equal to this value.
        attr_accessor :gte
        # Return results where the `created` field is less than this value.
        attr_accessor :lt
        # Return results where the `created` field is less than or equal to this value.
        attr_accessor :lte

        def initialize(gt: nil, gte: nil, lt: nil, lte: nil)
          @gt = gt
          @gte = gte
          @lt = lt
          @lte = lte
        end
      end
      # Similar to other List endpoints, filters results based on created timestamp. You can pass gt, gte, lt, and lte timestamp values.
      attr_accessor :created
      # A pagination cursor to fetch the previous page of the list. The value must be a ForwardingRequest ID.
      attr_accessor :ending_before
      # Specifies which fields in the response should be expanded.
      attr_accessor :expand
      # A limit on the number of objects to be returned. Limit can range between 1 and 100, and the default is 10.
      attr_accessor :limit
      # A pagination cursor to fetch the next page of the list. The value must be a ForwardingRequest ID.
      attr_accessor :starting_after

      def initialize(created: nil, ending_before: nil, expand: nil, limit: nil, starting_after: nil)
        @created = created
        @ending_before = ending_before
        @expand = expand
        @limit = limit
        @starting_after = starting_after
      end
    end
  end
end
