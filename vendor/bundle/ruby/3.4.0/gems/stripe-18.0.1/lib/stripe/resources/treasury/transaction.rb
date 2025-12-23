# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  module Treasury
    # Transactions represent changes to a [FinancialAccount's](https://stripe.com/docs/api#financial_accounts) balance.
    class Transaction < APIResource
      extend Stripe::APIOperations::List

      OBJECT_NAME = "treasury.transaction"
      def self.object_name
        "treasury.transaction"
      end

      class BalanceImpact < ::Stripe::StripeObject
        # The change made to funds the user can spend right now.
        attr_reader :cash
        # The change made to funds that are not spendable yet, but will become available at a later time.
        attr_reader :inbound_pending
        # The change made to funds in the account, but not spendable because they are being held for pending outbound flows.
        attr_reader :outbound_pending

        def self.inner_class_types
          @inner_class_types = {}
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end

      class FlowDetails < ::Stripe::StripeObject
        # You can reverse some [ReceivedCredits](https://stripe.com/docs/api#received_credits) depending on their network and source flow. Reversing a ReceivedCredit leads to the creation of a new object known as a CreditReversal.
        attr_reader :credit_reversal
        # You can reverse some [ReceivedDebits](https://stripe.com/docs/api#received_debits) depending on their network and source flow. Reversing a ReceivedDebit leads to the creation of a new object known as a DebitReversal.
        attr_reader :debit_reversal
        # Use [InboundTransfers](https://docs.stripe.com/docs/treasury/moving-money/financial-accounts/into/inbound-transfers) to add funds to your [FinancialAccount](https://stripe.com/docs/api#financial_accounts) via a PaymentMethod that is owned by you. The funds will be transferred via an ACH debit.
        #
        # Related guide: [Moving money with Treasury using InboundTransfer objects](https://docs.stripe.com/docs/treasury/moving-money/financial-accounts/into/inbound-transfers)
        attr_reader :inbound_transfer
        # When an [issued card](https://stripe.com/docs/issuing) is used to make a purchase, an Issuing `Authorization`
        # object is created. [Authorizations](https://stripe.com/docs/issuing/purchases/authorizations) must be approved for the
        # purchase to be completed successfully.
        #
        # Related guide: [Issued card authorizations](https://stripe.com/docs/issuing/purchases/authorizations)
        attr_reader :issuing_authorization
        # Use [OutboundPayments](https://docs.stripe.com/docs/treasury/moving-money/financial-accounts/out-of/outbound-payments) to send funds to another party's external bank account or [FinancialAccount](https://stripe.com/docs/api#financial_accounts). To send money to an account belonging to the same user, use an [OutboundTransfer](https://stripe.com/docs/api#outbound_transfers).
        #
        # Simulate OutboundPayment state changes with the `/v1/test_helpers/treasury/outbound_payments` endpoints. These methods can only be called on test mode objects.
        #
        # Related guide: [Moving money with Treasury using OutboundPayment objects](https://docs.stripe.com/docs/treasury/moving-money/financial-accounts/out-of/outbound-payments)
        attr_reader :outbound_payment
        # Use [OutboundTransfers](https://docs.stripe.com/docs/treasury/moving-money/financial-accounts/out-of/outbound-transfers) to transfer funds from a [FinancialAccount](https://stripe.com/docs/api#financial_accounts) to a PaymentMethod belonging to the same entity. To send funds to a different party, use [OutboundPayments](https://stripe.com/docs/api#outbound_payments) instead. You can send funds over ACH rails or through a domestic wire transfer to a user's own external bank account.
        #
        # Simulate OutboundTransfer state changes with the `/v1/test_helpers/treasury/outbound_transfers` endpoints. These methods can only be called on test mode objects.
        #
        # Related guide: [Moving money with Treasury using OutboundTransfer objects](https://docs.stripe.com/docs/treasury/moving-money/financial-accounts/out-of/outbound-transfers)
        attr_reader :outbound_transfer
        # ReceivedCredits represent funds sent to a [FinancialAccount](https://stripe.com/docs/api#financial_accounts) (for example, via ACH or wire). These money movements are not initiated from the FinancialAccount.
        attr_reader :received_credit
        # ReceivedDebits represent funds pulled from a [FinancialAccount](https://stripe.com/docs/api#financial_accounts). These are not initiated from the FinancialAccount.
        attr_reader :received_debit
        # Type of the flow that created the Transaction. Set to the same value as `flow_type`.
        attr_reader :type

        def self.inner_class_types
          @inner_class_types = {}
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end

      class StatusTransitions < ::Stripe::StripeObject
        # Timestamp describing when the Transaction changed status to `posted`.
        attr_reader :posted_at
        # Timestamp describing when the Transaction changed status to `void`.
        attr_reader :void_at

        def self.inner_class_types
          @inner_class_types = {}
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end
      # Amount (in cents) transferred.
      attr_reader :amount
      # Change to a FinancialAccount's balance
      attr_reader :balance_impact
      # Time at which the object was created. Measured in seconds since the Unix epoch.
      attr_reader :created
      # Three-letter [ISO currency code](https://www.iso.org/iso-4217-currency-codes.html), in lowercase. Must be a [supported currency](https://stripe.com/docs/currencies).
      attr_reader :currency
      # An arbitrary string attached to the object. Often useful for displaying to users.
      attr_reader :description
      # A list of TransactionEntries that are part of this Transaction. This cannot be expanded in any list endpoints.
      attr_reader :entries
      # The FinancialAccount associated with this object.
      attr_reader :financial_account
      # ID of the flow that created the Transaction.
      attr_reader :flow
      # Details of the flow that created the Transaction.
      attr_reader :flow_details
      # Type of the flow that created the Transaction.
      attr_reader :flow_type
      # Unique identifier for the object.
      attr_reader :id
      # Has the value `true` if the object exists in live mode or the value `false` if the object exists in test mode.
      attr_reader :livemode
      # String representing the object's type. Objects of the same type share the same value.
      attr_reader :object
      # Status of the Transaction.
      attr_reader :status
      # Attribute for field status_transitions
      attr_reader :status_transitions

      # Retrieves a list of Transaction objects.
      def self.list(params = {}, opts = {})
        request_stripe_object(
          method: :get,
          path: "/v1/treasury/transactions",
          params: params,
          opts: opts
        )
      end

      def self.inner_class_types
        @inner_class_types = {
          balance_impact: BalanceImpact,
          flow_details: FlowDetails,
          status_transitions: StatusTransitions,
        }
      end

      def self.field_remappings
        @field_remappings = {}
      end
    end
  end
end
