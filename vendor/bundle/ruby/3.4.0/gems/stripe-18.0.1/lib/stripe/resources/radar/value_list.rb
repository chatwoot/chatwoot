# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  module Radar
    # Value lists allow you to group values together which can then be referenced in rules.
    #
    # Related guide: [Default Stripe lists](https://stripe.com/docs/radar/lists#managing-list-items)
    class ValueList < APIResource
      extend Stripe::APIOperations::Create
      include Stripe::APIOperations::Delete
      extend Stripe::APIOperations::List
      include Stripe::APIOperations::Save

      OBJECT_NAME = "radar.value_list"
      def self.object_name
        "radar.value_list"
      end

      # The name of the value list for use in rules.
      attr_reader :alias
      # Time at which the object was created. Measured in seconds since the Unix epoch.
      attr_reader :created
      # The name or email address of the user who created this value list.
      attr_reader :created_by
      # Unique identifier for the object.
      attr_reader :id
      # The type of items in the value list. One of `card_fingerprint`, `card_bin`, `email`, `ip_address`, `country`, `string`, `case_sensitive_string`, `customer_id`, `sepa_debit_fingerprint`, or `us_bank_account_fingerprint`.
      attr_reader :item_type
      # List of items contained within this value list.
      attr_reader :list_items
      # Has the value `true` if the object exists in live mode or the value `false` if the object exists in test mode.
      attr_reader :livemode
      # Set of [key-value pairs](https://stripe.com/docs/api/metadata) that you can attach to an object. This can be useful for storing additional information about the object in a structured format.
      attr_reader :metadata
      # The name of the value list.
      attr_reader :name
      # String representing the object's type. Objects of the same type share the same value.
      attr_reader :object
      # Always true for a deleted object
      attr_reader :deleted

      # Creates a new ValueList object, which can then be referenced in rules.
      def self.create(params = {}, opts = {})
        request_stripe_object(
          method: :post,
          path: "/v1/radar/value_lists",
          params: params,
          opts: opts
        )
      end

      # Deletes a ValueList object, also deleting any items contained within the value list. To be deleted, a value list must not be referenced in any rules.
      def self.delete(value_list, params = {}, opts = {})
        request_stripe_object(
          method: :delete,
          path: format("/v1/radar/value_lists/%<value_list>s", { value_list: CGI.escape(value_list) }),
          params: params,
          opts: opts
        )
      end

      # Deletes a ValueList object, also deleting any items contained within the value list. To be deleted, a value list must not be referenced in any rules.
      def delete(params = {}, opts = {})
        request_stripe_object(
          method: :delete,
          path: format("/v1/radar/value_lists/%<value_list>s", { value_list: CGI.escape(self["id"]) }),
          params: params,
          opts: opts
        )
      end

      # Returns a list of ValueList objects. The objects are sorted in descending order by creation date, with the most recently created object appearing first.
      def self.list(params = {}, opts = {})
        request_stripe_object(
          method: :get,
          path: "/v1/radar/value_lists",
          params: params,
          opts: opts
        )
      end

      # Updates a ValueList object by setting the values of the parameters passed. Any parameters not provided will be left unchanged. Note that item_type is immutable.
      def self.update(value_list, params = {}, opts = {})
        request_stripe_object(
          method: :post,
          path: format("/v1/radar/value_lists/%<value_list>s", { value_list: CGI.escape(value_list) }),
          params: params,
          opts: opts
        )
      end

      def self.inner_class_types
        @inner_class_types = {}
      end

      def self.field_remappings
        @field_remappings = {}
      end
    end
  end
end
