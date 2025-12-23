# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  module Radar
    # Value list items allow you to add specific values to a given Radar value list, which can then be used in rules.
    #
    # Related guide: [Managing list items](https://stripe.com/docs/radar/lists#managing-list-items)
    class ValueListItem < APIResource
      extend Stripe::APIOperations::Create
      include Stripe::APIOperations::Delete
      extend Stripe::APIOperations::List

      OBJECT_NAME = "radar.value_list_item"
      def self.object_name
        "radar.value_list_item"
      end

      # Time at which the object was created. Measured in seconds since the Unix epoch.
      attr_reader :created
      # The name or email address of the user who added this item to the value list.
      attr_reader :created_by
      # Unique identifier for the object.
      attr_reader :id
      # Has the value `true` if the object exists in live mode or the value `false` if the object exists in test mode.
      attr_reader :livemode
      # String representing the object's type. Objects of the same type share the same value.
      attr_reader :object
      # The value of the item.
      attr_reader :value
      # The identifier of the value list this item belongs to.
      attr_reader :value_list
      # Always true for a deleted object
      attr_reader :deleted

      # Creates a new ValueListItem object, which is added to the specified parent value list.
      def self.create(params = {}, opts = {})
        request_stripe_object(
          method: :post,
          path: "/v1/radar/value_list_items",
          params: params,
          opts: opts
        )
      end

      # Deletes a ValueListItem object, removing it from its parent value list.
      def self.delete(item, params = {}, opts = {})
        request_stripe_object(
          method: :delete,
          path: format("/v1/radar/value_list_items/%<item>s", { item: CGI.escape(item) }),
          params: params,
          opts: opts
        )
      end

      # Deletes a ValueListItem object, removing it from its parent value list.
      def delete(params = {}, opts = {})
        request_stripe_object(
          method: :delete,
          path: format("/v1/radar/value_list_items/%<item>s", { item: CGI.escape(self["id"]) }),
          params: params,
          opts: opts
        )
      end

      # Returns a list of ValueListItem objects. The objects are sorted in descending order by creation date, with the most recently created object appearing first.
      def self.list(params = {}, opts = {})
        request_stripe_object(
          method: :get,
          path: "/v1/radar/value_list_items",
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
