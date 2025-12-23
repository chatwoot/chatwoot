# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  module Entitlements
    class FeatureListParams < ::Stripe::RequestParams
      # If set, filter results to only include features with the given archive status.
      attr_accessor :archived
      # A cursor for use in pagination. `ending_before` is an object ID that defines your place in the list. For instance, if you make a list request and receive 100 objects, starting with `obj_bar`, your subsequent call can include `ending_before=obj_bar` in order to fetch the previous page of the list.
      attr_accessor :ending_before
      # Specifies which fields in the response should be expanded.
      attr_accessor :expand
      # A limit on the number of objects to be returned. Limit can range between 1 and 100, and the default is 10.
      attr_accessor :limit
      # If set, filter results to only include features with the given lookup_key.
      attr_accessor :lookup_key
      # A cursor for use in pagination. `starting_after` is an object ID that defines your place in the list. For instance, if you make a list request and receive 100 objects, ending with `obj_foo`, your subsequent call can include `starting_after=obj_foo` in order to fetch the next page of the list.
      attr_accessor :starting_after

      def initialize(
        archived: nil,
        ending_before: nil,
        expand: nil,
        limit: nil,
        lookup_key: nil,
        starting_after: nil
      )
        @archived = archived
        @ending_before = ending_before
        @expand = expand
        @limit = limit
        @lookup_key = lookup_key
        @starting_after = starting_after
      end
    end
  end
end
