# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  module Issuing
    class PersonalizationDesignListParams < ::Stripe::RequestParams
      class Preferences < ::Stripe::RequestParams
        # Only return the personalization design that's set as the default. A connected account uses the Connect platform's default design if no personalization design is set as the default.
        attr_accessor :is_default
        # Only return the personalization design that is set as the Connect platform's default. This parameter is only applicable to connected accounts.
        attr_accessor :is_platform_default

        def initialize(is_default: nil, is_platform_default: nil)
          @is_default = is_default
          @is_platform_default = is_platform_default
        end
      end
      # A cursor for use in pagination. `ending_before` is an object ID that defines your place in the list. For instance, if you make a list request and receive 100 objects, starting with `obj_bar`, your subsequent call can include `ending_before=obj_bar` in order to fetch the previous page of the list.
      attr_accessor :ending_before
      # Specifies which fields in the response should be expanded.
      attr_accessor :expand
      # A limit on the number of objects to be returned. Limit can range between 1 and 100, and the default is 10.
      attr_accessor :limit
      # Only return personalization designs with the given lookup keys.
      attr_accessor :lookup_keys
      # Only return personalization designs with the given preferences.
      attr_accessor :preferences
      # A cursor for use in pagination. `starting_after` is an object ID that defines your place in the list. For instance, if you make a list request and receive 100 objects, ending with `obj_foo`, your subsequent call can include `starting_after=obj_foo` in order to fetch the next page of the list.
      attr_accessor :starting_after
      # Only return personalization designs with the given status.
      attr_accessor :status

      def initialize(
        ending_before: nil,
        expand: nil,
        limit: nil,
        lookup_keys: nil,
        preferences: nil,
        starting_after: nil,
        status: nil
      )
        @ending_before = ending_before
        @expand = expand
        @limit = limit
        @lookup_keys = lookup_keys
        @preferences = preferences
        @starting_after = starting_after
        @status = status
      end
    end
  end
end
