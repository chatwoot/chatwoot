# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  module Issuing
    class CardholderListParams < ::Stripe::RequestParams
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
      # Only return cardholders that were created during the given date interval.
      attr_accessor :created
      # Only return cardholders that have the given email address.
      attr_accessor :email
      # A cursor for use in pagination. `ending_before` is an object ID that defines your place in the list. For instance, if you make a list request and receive 100 objects, starting with `obj_bar`, your subsequent call can include `ending_before=obj_bar` in order to fetch the previous page of the list.
      attr_accessor :ending_before
      # Specifies which fields in the response should be expanded.
      attr_accessor :expand
      # A limit on the number of objects to be returned. Limit can range between 1 and 100, and the default is 10.
      attr_accessor :limit
      # Only return cardholders that have the given phone number.
      attr_accessor :phone_number
      # A cursor for use in pagination. `starting_after` is an object ID that defines your place in the list. For instance, if you make a list request and receive 100 objects, ending with `obj_foo`, your subsequent call can include `starting_after=obj_foo` in order to fetch the next page of the list.
      attr_accessor :starting_after
      # Only return cardholders that have the given status. One of `active`, `inactive`, or `blocked`.
      attr_accessor :status
      # Only return cardholders that have the given type. One of `individual` or `company`.
      attr_accessor :type

      def initialize(
        created: nil,
        email: nil,
        ending_before: nil,
        expand: nil,
        limit: nil,
        phone_number: nil,
        starting_after: nil,
        status: nil,
        type: nil
      )
        @created = created
        @email = email
        @ending_before = ending_before
        @expand = expand
        @limit = limit
        @phone_number = phone_number
        @starting_after = starting_after
        @status = status
        @type = type
      end
    end
  end
end
