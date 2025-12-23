# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  module Treasury
    # ReceivedDebits represent funds pulled from a [FinancialAccount](https://stripe.com/docs/api#financial_accounts). These are not initiated from the FinancialAccount.
    class ReceivedDebit < APIResource
      extend Stripe::APIOperations::List

      OBJECT_NAME = "treasury.received_debit"
      def self.object_name
        "treasury.received_debit"
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
        # The DebitReversal created as a result of this ReceivedDebit being reversed.
        attr_reader :debit_reversal
        # Set if the ReceivedDebit is associated with an InboundTransfer's return of funds.
        attr_reader :inbound_transfer
        # Set if the ReceivedDebit was created due to an [Issuing Authorization](https://stripe.com/docs/api#issuing_authorizations) object.
        attr_reader :issuing_authorization
        # Set if the ReceivedDebit is also viewable as an [Issuing Dispute](https://stripe.com/docs/api#issuing_disputes) object.
        attr_reader :issuing_transaction
        # Set if the ReceivedDebit was created due to a [Payout](https://stripe.com/docs/api#payouts) object.
        attr_reader :payout

        def self.inner_class_types
          @inner_class_types = {}
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end

      class ReversalDetails < ::Stripe::StripeObject
        # Time before which a ReceivedDebit can be reversed.
        attr_reader :deadline
        # Set if a ReceivedDebit can't be reversed.
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
      # Reason for the failure. A ReceivedDebit might fail because the FinancialAccount doesn't have sufficient funds, is closed, or is frozen.
      attr_reader :failure_code
      # The FinancialAccount that funds were pulled from.
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
      # The network used for the ReceivedDebit.
      attr_reader :network
      # String representing the object's type. Objects of the same type share the same value.
      attr_reader :object
      # Details describing when a ReceivedDebit might be reversed.
      attr_reader :reversal_details
      # Status of the ReceivedDebit. ReceivedDebits are created with a status of either `succeeded` (approved) or `failed` (declined). The failure reason can be found under the `failure_code`.
      attr_reader :status
      # The Transaction associated with this object.
      attr_reader :transaction

      # Returns a list of ReceivedDebits.
      def self.list(params = {}, opts = {})
        request_stripe_object(
          method: :get,
          path: "/v1/treasury/received_debits",
          params: params,
          opts: opts
        )
      end

      def test_helpers
        TestHelpers.new(self)
      end

      class TestHelpers < APIResourceTestHelpers
        RESOURCE_CLASS = ReceivedDebit
        def self.resource_class
          "ReceivedDebit"
        end

        # Use this endpoint to simulate a test mode ReceivedDebit initiated by a third party. In live mode, you can't directly create ReceivedDebits initiated by third parties.
        def self.create(params = {}, opts = {})
          request_stripe_object(
            method: :post,
            path: "/v1/test_helpers/treasury/received_debits",
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
