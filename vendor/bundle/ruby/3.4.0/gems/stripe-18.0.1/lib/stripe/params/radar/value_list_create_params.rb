# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  module Radar
    class ValueListCreateParams < ::Stripe::RequestParams
      # The name of the value list for use in rules.
      attr_accessor :alias
      # Specifies which fields in the response should be expanded.
      attr_accessor :expand
      # Type of the items in the value list. One of `card_fingerprint`, `card_bin`, `email`, `ip_address`, `country`, `string`, `case_sensitive_string`, `customer_id`, `sepa_debit_fingerprint`, or `us_bank_account_fingerprint`. Use `string` if the item type is unknown or mixed.
      attr_accessor :item_type
      # Set of [key-value pairs](https://stripe.com/docs/api/metadata) that you can attach to an object. This can be useful for storing additional information about the object in a structured format. Individual keys can be unset by posting an empty value to them. All keys can be unset by posting an empty value to `metadata`.
      attr_accessor :metadata
      # The human-readable name of the value list.
      attr_accessor :name

      def initialize(alias_: nil, expand: nil, item_type: nil, metadata: nil, name: nil)
        @alias = alias_
        @expand = expand
        @item_type = item_type
        @metadata = metadata
        @name = name
      end
    end
  end
end
