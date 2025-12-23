# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  module Treasury
    # You can reverse some [ReceivedCredits](https://stripe.com/docs/api#received_credits) depending on their network and source flow. Reversing a ReceivedCredit leads to the creation of a new object known as a CreditReversal.
    class CreditReversal < APIResource
      extend Stripe::APIOperations::Create
      extend Stripe::APIOperations::List

      OBJECT_NAME = "treasury.credit_reversal"
      def self.object_name
        "treasury.credit_reversal"
      end

      class StatusTransitions < ::Stripe::StripeObject
        # Timestamp describing when the CreditReversal changed status to `posted`
        attr_reader :posted_at

        def self.inner_class_types
          @inner_class_types = {}
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end
      # Amount (in cents) transferred.
      attr_reader :amount
      # Time at which the object was created. Measured in seconds since the Unix epoch.
      attr_reader :created
      # Three-letter [ISO currency code](https://www.iso.org/iso-4217-currency-codes.html), in lowercase. Must be a [supported currency](https://stripe.com/docs/currencies).
      attr_reader :currency
      # The FinancialAccount to reverse funds from.
      attr_reader :financial_account
      # A [hosted transaction receipt](https://stripe.com/docs/treasury/moving-money/regulatory-receipts) URL that is provided when money movement is considered regulated under Stripe's money transmission licenses.
      attr_reader :hosted_regulatory_receipt_url
      # Unique identifier for the object.
      attr_reader :id
      # Has the value `true` if the object exists in live mode or the value `false` if the object exists in test mode.
      attr_reader :livemode
      # Set of [key-value pairs](https://stripe.com/docs/api/metadata) that you can attach to an object. This can be useful for storing additional information about the object in a structured format.
      attr_reader :metadata
      # The rails used to reverse the funds.
      attr_reader :network
      # String representing the object's type. Objects of the same type share the same value.
      attr_reader :object
      # The ReceivedCredit being reversed.
      attr_reader :received_credit
      # Status of the CreditReversal
      attr_reader :status
      # Attribute for field status_transitions
      attr_reader :status_transitions
      # The Transaction associated with this object.
      attr_reader :transaction

      # Reverses a ReceivedCredit and creates a CreditReversal object.
      def self.create(params = {}, opts = {})
        request_stripe_object(
          method: :post,
          path: "/v1/treasury/credit_reversals",
          params: params,
          opts: opts
        )
      end

      # Returns a list of CreditReversals.
      def self.list(params = {}, opts = {})
        request_stripe_object(
          method: :get,
          path: "/v1/treasury/credit_reversals",
          params: params,
          opts: opts
        )
      end

      def self.inner_class_types
        @inner_class_types = { status_transitions: StatusTransitions }
      end

      def self.field_remappings
        @field_remappings = {}
      end
    end
  end
end
