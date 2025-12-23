# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  module Tax
    class TransactionCreateReversalParams < ::Stripe::RequestParams
      class LineItem < ::Stripe::RequestParams
        # The amount to reverse, in the [smallest currency unit](https://stripe.com/docs/currencies#zero-decimal) in negative.
        attr_accessor :amount
        # The amount of tax to reverse, in the [smallest currency unit](https://stripe.com/docs/currencies#zero-decimal) in negative.
        attr_accessor :amount_tax
        # Set of [key-value pairs](https://stripe.com/docs/api/metadata) that you can attach to an object. This can be useful for storing additional information about the object in a structured format.
        attr_accessor :metadata
        # The `id` of the line item to reverse in the original transaction.
        attr_accessor :original_line_item
        # The quantity reversed. Appears in [tax exports](https://stripe.com/docs/tax/reports), but does not affect the amount of tax reversed.
        attr_accessor :quantity
        # A custom identifier for this line item in the reversal transaction, such as 'L1-refund'.
        attr_accessor :reference

        def initialize(
          amount: nil,
          amount_tax: nil,
          metadata: nil,
          original_line_item: nil,
          quantity: nil,
          reference: nil
        )
          @amount = amount
          @amount_tax = amount_tax
          @metadata = metadata
          @original_line_item = original_line_item
          @quantity = quantity
          @reference = reference
        end
      end

      class ShippingCost < ::Stripe::RequestParams
        # The amount to reverse, in the [smallest currency unit](https://stripe.com/docs/currencies#zero-decimal) in negative.
        attr_accessor :amount
        # The amount of tax to reverse, in the [smallest currency unit](https://stripe.com/docs/currencies#zero-decimal) in negative.
        attr_accessor :amount_tax

        def initialize(amount: nil, amount_tax: nil)
          @amount = amount
          @amount_tax = amount_tax
        end
      end
      # Specifies which fields in the response should be expanded.
      attr_accessor :expand
      # A flat amount to reverse across the entire transaction, in the [smallest currency unit](https://stripe.com/docs/currencies#zero-decimal) in negative. This value represents the total amount to refund from the transaction, including taxes.
      attr_accessor :flat_amount
      # The line item amounts to reverse.
      attr_accessor :line_items
      # Set of [key-value pairs](https://stripe.com/docs/api/metadata) that you can attach to an object. This can be useful for storing additional information about the object in a structured format. Individual keys can be unset by posting an empty value to them. All keys can be unset by posting an empty value to `metadata`.
      attr_accessor :metadata
      # If `partial`, the provided line item or shipping cost amounts are reversed. If `full`, the original transaction is fully reversed.
      attr_accessor :mode
      # The ID of the Transaction to partially or fully reverse.
      attr_accessor :original_transaction
      # A custom identifier for this reversal, such as `myOrder_123-refund_1`, which must be unique across all transactions. The reference helps identify this reversal transaction in exported [tax reports](https://stripe.com/docs/tax/reports).
      attr_accessor :reference
      # The shipping cost to reverse.
      attr_accessor :shipping_cost

      def initialize(
        expand: nil,
        flat_amount: nil,
        line_items: nil,
        metadata: nil,
        mode: nil,
        original_transaction: nil,
        reference: nil,
        shipping_cost: nil
      )
        @expand = expand
        @flat_amount = flat_amount
        @line_items = line_items
        @metadata = metadata
        @mode = mode
        @original_transaction = original_transaction
        @reference = reference
        @shipping_cost = shipping_cost
      end
    end
  end
end
