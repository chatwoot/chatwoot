# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  module Tax
    class TransactionCreateFromCalculationParams < ::Stripe::RequestParams
      # Tax Calculation ID to be used as input when creating the transaction.
      attr_accessor :calculation
      # Specifies which fields in the response should be expanded.
      attr_accessor :expand
      # Set of [key-value pairs](https://stripe.com/docs/api/metadata) that you can attach to an object. This can be useful for storing additional information about the object in a structured format. Individual keys can be unset by posting an empty value to them. All keys can be unset by posting an empty value to `metadata`.
      attr_accessor :metadata
      # The Unix timestamp representing when the tax liability is assumed or reduced, which determines the liability posting period and handling in tax liability reports. The timestamp must fall within the `tax_date` and the current time, unless the `tax_date` is scheduled in advance. Defaults to the current time.
      attr_accessor :posted_at
      # A custom order or sale identifier, such as 'myOrder_123'. Must be unique across all transactions, including reversals.
      attr_accessor :reference

      def initialize(calculation: nil, expand: nil, metadata: nil, posted_at: nil, reference: nil)
        @calculation = calculation
        @expand = expand
        @metadata = metadata
        @posted_at = posted_at
        @reference = reference
      end
    end
  end
end
