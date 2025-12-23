# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  module FinancialConnections
    # A Transaction represents a real transaction that affects a Financial Connections Account balance.
    class Transaction < APIResource
      extend Stripe::APIOperations::List

      OBJECT_NAME = "financial_connections.transaction"
      def self.object_name
        "financial_connections.transaction"
      end

      class StatusTransitions < ::Stripe::StripeObject
        # Time at which this transaction posted. Measured in seconds since the Unix epoch.
        attr_reader :posted_at
        # Time at which this transaction was voided. Measured in seconds since the Unix epoch.
        attr_reader :void_at

        def self.inner_class_types
          @inner_class_types = {}
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end
      # The ID of the Financial Connections Account this transaction belongs to.
      attr_reader :account
      # The amount of this transaction, in cents (or local equivalent).
      attr_reader :amount
      # Three-letter [ISO currency code](https://www.iso.org/iso-4217-currency-codes.html), in lowercase. Must be a [supported currency](https://stripe.com/docs/currencies).
      attr_reader :currency
      # The description of this transaction.
      attr_reader :description
      # Unique identifier for the object.
      attr_reader :id
      # Has the value `true` if the object exists in live mode or the value `false` if the object exists in test mode.
      attr_reader :livemode
      # String representing the object's type. Objects of the same type share the same value.
      attr_reader :object
      # The status of the transaction.
      attr_reader :status
      # Attribute for field status_transitions
      attr_reader :status_transitions
      # Time at which the transaction was transacted. Measured in seconds since the Unix epoch.
      attr_reader :transacted_at
      # The token of the transaction refresh that last updated or created this transaction.
      attr_reader :transaction_refresh
      # Time at which the object was last updated. Measured in seconds since the Unix epoch.
      attr_reader :updated

      # Returns a list of Financial Connections Transaction objects.
      def self.list(params = {}, opts = {})
        request_stripe_object(
          method: :get,
          path: "/v1/financial_connections/transactions",
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
