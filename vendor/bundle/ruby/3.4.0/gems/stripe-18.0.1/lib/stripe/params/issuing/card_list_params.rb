# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  module Issuing
    class CardListParams < ::Stripe::RequestParams
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
      # Only return cards belonging to the Cardholder with the provided ID.
      attr_accessor :cardholder
      # Only return cards that were issued during the given date interval.
      attr_accessor :created
      # A cursor for use in pagination. `ending_before` is an object ID that defines your place in the list. For instance, if you make a list request and receive 100 objects, starting with `obj_bar`, your subsequent call can include `ending_before=obj_bar` in order to fetch the previous page of the list.
      attr_accessor :ending_before
      # Only return cards that have the given expiration month.
      attr_accessor :exp_month
      # Only return cards that have the given expiration year.
      attr_accessor :exp_year
      # Specifies which fields in the response should be expanded.
      attr_accessor :expand
      # Only return cards that have the given last four digits.
      attr_accessor :last4
      # A limit on the number of objects to be returned. Limit can range between 1 and 100, and the default is 10.
      attr_accessor :limit
      # Attribute for param field personalization_design
      attr_accessor :personalization_design
      # A cursor for use in pagination. `starting_after` is an object ID that defines your place in the list. For instance, if you make a list request and receive 100 objects, ending with `obj_foo`, your subsequent call can include `starting_after=obj_foo` in order to fetch the next page of the list.
      attr_accessor :starting_after
      # Only return cards that have the given status. One of `active`, `inactive`, or `canceled`.
      attr_accessor :status
      # Only return cards that have the given type. One of `virtual` or `physical`.
      attr_accessor :type

      def initialize(
        cardholder: nil,
        created: nil,
        ending_before: nil,
        exp_month: nil,
        exp_year: nil,
        expand: nil,
        last4: nil,
        limit: nil,
        personalization_design: nil,
        starting_after: nil,
        status: nil,
        type: nil
      )
        @cardholder = cardholder
        @created = created
        @ending_before = ending_before
        @exp_month = exp_month
        @exp_year = exp_year
        @expand = expand
        @last4 = last4
        @limit = limit
        @personalization_design = personalization_design
        @starting_after = starting_after
        @status = status
        @type = type
      end
    end
  end
end
