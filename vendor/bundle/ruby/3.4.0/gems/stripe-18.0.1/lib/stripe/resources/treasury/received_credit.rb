# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  module Treasury
    # ReceivedCredits represent funds sent to a [FinancialAccount](https://stripe.com/docs/api#financial_accounts) (for example, via ACH or wire). These money movements are not initiated from the FinancialAccount.
    class ReceivedCredit < APIResource
      extend Stripe::APIOperations::List

      OBJECT_NAME = "treasury.received_credit"
      def self.object_name
        "treasury.received_credit"
      end

      class InitiatingPaymentMethodDetails < ::Stripe::StripeObject
        class BillingDetails < ::Stripe::StripeObject
          class Address < ::Stripe::StripeObject
            # City, district, suburb, town, or village.
            attr_reader :city
            # Two-letter country code ([ISO 3166-1 alpha-2](https://en.wikipedia.org/wiki/ISO_3166-1_alpha-2)).
            attr_reader :country
            # Address line 1, such as the street, PO Box, or company name.
            attr_reader :line1
            # Address line 2, such as the apartment, suite, unit, or building.
            attr_reader :line2
            # ZIP or postal code.
            attr_reader :postal_code
            # State, county, province, or region.
            attr_reader :state

            def self.inner_class_types
              @inner_class_types = {}
            end

            def self.field_remappings
              @field_remappings = {}
            end
          end
          # Attribute for field address
          attr_reader :address
          # Email address.
          attr_reader :email
          # Full name.
          attr_reader :name

          def self.inner_class_types
            @inner_class_types = { address: Address }
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end

        class FinancialAccount < ::Stripe::StripeObject
          # The FinancialAccount ID.
          attr_reader :id
          # The rails the ReceivedCredit was sent over. A FinancialAccount can only send funds over `stripe`.
          attr_reader :network

          def self.inner_class_types
            @inner_class_types = {}
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end

        class UsBankAccount < ::Stripe::StripeObject
          # Bank name.
          attr_reader :bank_name
          # The last four digits of the bank account number.
          attr_reader :last4
          # The routing number for the bank account.
          attr_reader :routing_number

          def self.inner_class_types
            @inner_class_types = {}
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end
        # Set when `type` is `balance`.
        attr_reader :balance
        # Attribute for field billing_details
        attr_reader :billing_details
        # Attribute for field financial_account
        attr_reader :financial_account
        # Set when `type` is `issuing_card`. This is an [Issuing Card](https://stripe.com/docs/api#issuing_cards) ID.
        attr_reader :issuing_card
        # Polymorphic type matching the originating money movement's source. This can be an external account, a Stripe balance, or a FinancialAccount.
        attr_reader :type
        # Attribute for field us_bank_account
        attr_reader :us_bank_account

        def self.inner_class_types
          @inner_class_types = {
            billing_details: BillingDetails,
            financial_account: FinancialAccount,
            us_bank_account: UsBankAccount,
          }
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end

      class LinkedFlows < ::Stripe::StripeObject
        class SourceFlowDetails < ::Stripe::StripeObject
          # You can reverse some [ReceivedCredits](https://stripe.com/docs/api#received_credits) depending on their network and source flow. Reversing a ReceivedCredit leads to the creation of a new object known as a CreditReversal.
          attr_reader :credit_reversal
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
          # A `Payout` object is created when you receive funds from Stripe, or when you
          # initiate a payout to either a bank account or debit card of a [connected
          # Stripe account](/docs/connect/bank-debit-card-payouts). You can retrieve individual payouts,
          # and list all payouts. Payouts are made on [varying
          # schedules](/docs/connect/manage-payout-schedule), depending on your country and
          # industry.
          #
          # Related guide: [Receiving payouts](https://stripe.com/docs/payouts)
          attr_reader :payout
          # The type of the source flow that originated the ReceivedCredit.
          attr_reader :type

          def self.inner_class_types
            @inner_class_types = {}
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end
        # The CreditReversal created as a result of this ReceivedCredit being reversed.
        attr_reader :credit_reversal
        # Set if the ReceivedCredit was created due to an [Issuing Authorization](https://stripe.com/docs/api#issuing_authorizations) object.
        attr_reader :issuing_authorization
        # Set if the ReceivedCredit is also viewable as an [Issuing transaction](https://stripe.com/docs/api#issuing_transactions) object.
        attr_reader :issuing_transaction
        # ID of the source flow. Set if `network` is `stripe` and the source flow is visible to the user. Examples of source flows include OutboundPayments, payouts, or CreditReversals.
        attr_reader :source_flow
        # The expandable object of the source flow.
        attr_reader :source_flow_details
        # The type of flow that originated the ReceivedCredit (for example, `outbound_payment`).
        attr_reader :source_flow_type

        def self.inner_class_types
          @inner_class_types = { source_flow_details: SourceFlowDetails }
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end

      class ReversalDetails < ::Stripe::StripeObject
        # Time before which a ReceivedCredit can be reversed.
        attr_reader :deadline
        # Set if a ReceivedCredit cannot be reversed.
        attr_reader :restricted_reason

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
      # An arbitrary string attached to the object. Often useful for displaying to users.
      attr_reader :description
      # Reason for the failure. A ReceivedCredit might fail because the receiving FinancialAccount is closed or frozen.
      attr_reader :failure_code
      # The FinancialAccount that received the funds.
      attr_reader :financial_account
      # A [hosted transaction receipt](https://stripe.com/docs/treasury/moving-money/regulatory-receipts) URL that is provided when money movement is considered regulated under Stripe's money transmission licenses.
      attr_reader :hosted_regulatory_receipt_url
      # Unique identifier for the object.
      attr_reader :id
      # Attribute for field initiating_payment_method_details
      attr_reader :initiating_payment_method_details
      # Attribute for field linked_flows
      attr_reader :linked_flows
      # Has the value `true` if the object exists in live mode or the value `false` if the object exists in test mode.
      attr_reader :livemode
      # The rails used to send the funds.
      attr_reader :network
      # String representing the object's type. Objects of the same type share the same value.
      attr_reader :object
      # Details describing when a ReceivedCredit may be reversed.
      attr_reader :reversal_details
      # Status of the ReceivedCredit. ReceivedCredits are created either `succeeded` (approved) or `failed` (declined). If a ReceivedCredit is declined, the failure reason can be found in the `failure_code` field.
      attr_reader :status
      # The Transaction associated with this object.
      attr_reader :transaction

      # Returns a list of ReceivedCredits.
      def self.list(params = {}, opts = {})
        request_stripe_object(
          method: :get,
          path: "/v1/treasury/received_credits",
          params: params,
          opts: opts
        )
      end

      def test_helpers
        TestHelpers.new(self)
      end

      class TestHelpers < APIResourceTestHelpers
        RESOURCE_CLASS = ReceivedCredit
        def self.resource_class
          "ReceivedCredit"
        end

        # Use this endpoint to simulate a test mode ReceivedCredit initiated by a third party. In live mode, you can't directly create ReceivedCredits initiated by third parties.
        def self.create(params = {}, opts = {})
          request_stripe_object(
            method: :post,
            path: "/v1/test_helpers/treasury/received_credits",
            params: params,
            opts: opts
          )
        end
      end

      def self.inner_class_types
        @inner_class_types = {
          initiating_payment_method_details: InitiatingPaymentMethodDetails,
          linked_flows: LinkedFlows,
          reversal_details: ReversalDetails,
        }
      end

      def self.field_remappings
        @field_remappings = {}
      end
    end
  end
end
