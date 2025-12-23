# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  module Treasury
    class InboundTransferCreateParams < ::Stripe::RequestParams
      # Amount (in cents) to be transferred.
      attr_accessor :amount
      # Three-letter [ISO currency code](https://www.iso.org/iso-4217-currency-codes.html), in lowercase. Must be a [supported currency](https://stripe.com/docs/currencies).
      attr_accessor :currency
      # An arbitrary string attached to the object. Often useful for displaying to users.
      attr_accessor :description
      # Specifies which fields in the response should be expanded.
      attr_accessor :expand
      # The FinancialAccount to send funds to.
      attr_accessor :financial_account
      # Set of [key-value pairs](https://stripe.com/docs/api/metadata) that you can attach to an object. This can be useful for storing additional information about the object in a structured format. Individual keys can be unset by posting an empty value to them. All keys can be unset by posting an empty value to `metadata`.
      attr_accessor :metadata
      # The origin payment method to be debited for the InboundTransfer.
      attr_accessor :origin_payment_method
      # The complete description that appears on your customers' statements. Maximum 10 characters.
      attr_accessor :statement_descriptor

      def initialize(
        amount: nil,
        currency: nil,
        description: nil,
        expand: nil,
        financial_account: nil,
        metadata: nil,
        origin_payment_method: nil,
        statement_descriptor: nil
      )
        @amount = amount
        @currency = currency
        @description = description
        @expand = expand
        @financial_account = financial_account
        @metadata = metadata
        @origin_payment_method = origin_payment_method
        @statement_descriptor = statement_descriptor
      end
    end
  end
end
