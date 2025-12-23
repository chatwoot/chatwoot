# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  module Treasury
    # Use [OutboundTransfers](https://docs.stripe.com/docs/treasury/moving-money/financial-accounts/out-of/outbound-transfers) to transfer funds from a [FinancialAccount](https://stripe.com/docs/api#financial_accounts) to a PaymentMethod belonging to the same entity. To send funds to a different party, use [OutboundPayments](https://stripe.com/docs/api#outbound_payments) instead. You can send funds over ACH rails or through a domestic wire transfer to a user's own external bank account.
    #
    # Simulate OutboundTransfer state changes with the `/v1/test_helpers/treasury/outbound_transfers` endpoints. These methods can only be called on test mode objects.
    #
    # Related guide: [Moving money with Treasury using OutboundTransfer objects](https://docs.stripe.com/docs/treasury/moving-money/financial-accounts/out-of/outbound-transfers)
    class OutboundTransfer < APIResource
      extend Stripe::APIOperations::Create
      extend Stripe::APIOperations::List

      OBJECT_NAME = "treasury.outbound_transfer"
      def self.object_name
        "treasury.outbound_transfer"
      end

      class DestinationPaymentMethodDetails < ::Stripe::StripeObject
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
          # Token of the FinancialAccount.
          attr_reader :id
          # The rails used to send funds.
          attr_reader :network

          def self.inner_class_types
            @inner_class_types = {}
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end

        class UsBankAccount < ::Stripe::StripeObject
          # Account holder type: individual or company.
          attr_reader :account_holder_type
          # Account type: checkings or savings. Defaults to checking if omitted.
          attr_reader :account_type
          # Name of the bank associated with the bank account.
          attr_reader :bank_name
          # Uniquely identifies this particular bank account. You can use this attribute to check whether two bank accounts are the same.
          attr_reader :fingerprint
          # Last four digits of the bank account number.
          attr_reader :last4
          # ID of the mandate used to make this payment.
          attr_reader :mandate
          # The network rails used. See the [docs](https://stripe.com/docs/treasury/money-movement/timelines) to learn more about money movement timelines for each network type.
          attr_reader :network
          # Routing number of the bank account.
          attr_reader :routing_number

          def self.inner_class_types
            @inner_class_types = {}
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end
        # Attribute for field billing_details
        attr_reader :billing_details
        # Attribute for field financial_account
        attr_reader :financial_account
        # The type of the payment method used in the OutboundTransfer.
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

      class ReturnedDetails < ::Stripe::StripeObject
        # Reason for the return.
        attr_reader :code
        # The Transaction associated with this object.
        attr_reader :transaction

        def self.inner_class_types
          @inner_class_types = {}
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end

      class StatusTransitions < ::Stripe::StripeObject
        # Timestamp describing when an OutboundTransfer changed status to `canceled`
        attr_reader :canceled_at
        # Timestamp describing when an OutboundTransfer changed status to `failed`
        attr_reader :failed_at
        # Timestamp describing when an OutboundTransfer changed status to `posted`
        attr_reader :posted_at
        # Timestamp describing when an OutboundTransfer changed status to `returned`
        attr_reader :returned_at

        def self.inner_class_types
          @inner_class_types = {}
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end

      class TrackingDetails < ::Stripe::StripeObject
        class Ach < ::Stripe::StripeObject
          # ACH trace ID of the OutboundTransfer for transfers sent over the `ach` network.
          attr_reader :trace_id

          def self.inner_class_types
            @inner_class_types = {}
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end

        class UsDomesticWire < ::Stripe::StripeObject
          # CHIPS System Sequence Number (SSN) of the OutboundTransfer for transfers sent over the `us_domestic_wire` network.
          attr_reader :chips
          # IMAD of the OutboundTransfer for transfers sent over the `us_domestic_wire` network.
          attr_reader :imad
          # OMAD of the OutboundTransfer for transfers sent over the `us_domestic_wire` network.
          attr_reader :omad

          def self.inner_class_types
            @inner_class_types = {}
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end
        # Attribute for field ach
        attr_reader :ach
        # The US bank account network used to send funds.
        attr_reader :type
        # Attribute for field us_domestic_wire
        attr_reader :us_domestic_wire

        def self.inner_class_types
          @inner_class_types = { ach: Ach, us_domestic_wire: UsDomesticWire }
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end
      # Amount (in cents) transferred.
      attr_reader :amount
      # Returns `true` if the object can be canceled, and `false` otherwise.
      attr_reader :cancelable
      # Time at which the object was created. Measured in seconds since the Unix epoch.
      attr_reader :created
      # Three-letter [ISO currency code](https://www.iso.org/iso-4217-currency-codes.html), in lowercase. Must be a [supported currency](https://stripe.com/docs/currencies).
      attr_reader :currency
      # An arbitrary string attached to the object. Often useful for displaying to users.
      attr_reader :description
      # The PaymentMethod used as the payment instrument for an OutboundTransfer.
      attr_reader :destination_payment_method
      # Attribute for field destination_payment_method_details
      attr_reader :destination_payment_method_details
      # The date when funds are expected to arrive in the destination account.
      attr_reader :expected_arrival_date
      # The FinancialAccount that funds were pulled from.
      attr_reader :financial_account
      # A [hosted transaction receipt](https://stripe.com/docs/treasury/moving-money/regulatory-receipts) URL that is provided when money movement is considered regulated under Stripe's money transmission licenses.
      attr_reader :hosted_regulatory_receipt_url
      # Unique identifier for the object.
      attr_reader :id
      # Has the value `true` if the object exists in live mode or the value `false` if the object exists in test mode.
      attr_reader :livemode
      # Set of [key-value pairs](https://stripe.com/docs/api/metadata) that you can attach to an object. This can be useful for storing additional information about the object in a structured format.
      attr_reader :metadata
      # String representing the object's type. Objects of the same type share the same value.
      attr_reader :object
      # Details about a returned OutboundTransfer. Only set when the status is `returned`.
      attr_reader :returned_details
      # Information about the OutboundTransfer to be sent to the recipient account.
      attr_reader :statement_descriptor
      # Current status of the OutboundTransfer: `processing`, `failed`, `canceled`, `posted`, `returned`. An OutboundTransfer is `processing` if it has been created and is pending. The status changes to `posted` once the OutboundTransfer has been "confirmed" and funds have left the account, or to `failed` or `canceled`. If an OutboundTransfer fails to arrive at its destination, its status will change to `returned`.
      attr_reader :status
      # Attribute for field status_transitions
      attr_reader :status_transitions
      # Details about network-specific tracking information if available.
      attr_reader :tracking_details
      # The Transaction associated with this object.
      attr_reader :transaction

      # An OutboundTransfer can be canceled if the funds have not yet been paid out.
      def cancel(params = {}, opts = {})
        request_stripe_object(
          method: :post,
          path: format("/v1/treasury/outbound_transfers/%<outbound_transfer>s/cancel", { outbound_transfer: CGI.escape(self["id"]) }),
          params: params,
          opts: opts
        )
      end

      # An OutboundTransfer can be canceled if the funds have not yet been paid out.
      def self.cancel(outbound_transfer, params = {}, opts = {})
        request_stripe_object(
          method: :post,
          path: format("/v1/treasury/outbound_transfers/%<outbound_transfer>s/cancel", { outbound_transfer: CGI.escape(outbound_transfer) }),
          params: params,
          opts: opts
        )
      end

      # Creates an OutboundTransfer.
      def self.create(params = {}, opts = {})
        request_stripe_object(
          method: :post,
          path: "/v1/treasury/outbound_transfers",
          params: params,
          opts: opts
        )
      end

      # Returns a list of OutboundTransfers sent from the specified FinancialAccount.
      def self.list(params = {}, opts = {})
        request_stripe_object(
          method: :get,
          path: "/v1/treasury/outbound_transfers",
          params: params,
          opts: opts
        )
      end

      def test_helpers
        TestHelpers.new(self)
      end

      class TestHelpers < APIResourceTestHelpers
        RESOURCE_CLASS = OutboundTransfer
        def self.resource_class
          "OutboundTransfer"
        end

        # Transitions a test mode created OutboundTransfer to the failed status. The OutboundTransfer must already be in the processing state.
        def self.fail(outbound_transfer, params = {}, opts = {})
          request_stripe_object(
            method: :post,
            path: format("/v1/test_helpers/treasury/outbound_transfers/%<outbound_transfer>s/fail", { outbound_transfer: CGI.escape(outbound_transfer) }),
            params: params,
            opts: opts
          )
        end

        # Transitions a test mode created OutboundTransfer to the failed status. The OutboundTransfer must already be in the processing state.
        def fail(params = {}, opts = {})
          @resource.request_stripe_object(
            method: :post,
            path: format("/v1/test_helpers/treasury/outbound_transfers/%<outbound_transfer>s/fail", { outbound_transfer: CGI.escape(@resource["id"]) }),
            params: params,
            opts: opts
          )
        end

        # Transitions a test mode created OutboundTransfer to the posted status. The OutboundTransfer must already be in the processing state.
        def self.post(outbound_transfer, params = {}, opts = {})
          request_stripe_object(
            method: :post,
            path: format("/v1/test_helpers/treasury/outbound_transfers/%<outbound_transfer>s/post", { outbound_transfer: CGI.escape(outbound_transfer) }),
            params: params,
            opts: opts
          )
        end

        # Transitions a test mode created OutboundTransfer to the posted status. The OutboundTransfer must already be in the processing state.
        def post(params = {}, opts = {})
          @resource.request_stripe_object(
            method: :post,
            path: format("/v1/test_helpers/treasury/outbound_transfers/%<outbound_transfer>s/post", { outbound_transfer: CGI.escape(@resource["id"]) }),
            params: params,
            opts: opts
          )
        end

        # Transitions a test mode created OutboundTransfer to the returned status. The OutboundTransfer must already be in the processing state.
        def self.return_outbound_transfer(outbound_transfer, params = {}, opts = {})
          request_stripe_object(
            method: :post,
            path: format("/v1/test_helpers/treasury/outbound_transfers/%<outbound_transfer>s/return", { outbound_transfer: CGI.escape(outbound_transfer) }),
            params: params,
            opts: opts
          )
        end

        # Transitions a test mode created OutboundTransfer to the returned status. The OutboundTransfer must already be in the processing state.
        def return_outbound_transfer(params = {}, opts = {})
          @resource.request_stripe_object(
            method: :post,
            path: format("/v1/test_helpers/treasury/outbound_transfers/%<outbound_transfer>s/return", { outbound_transfer: CGI.escape(@resource["id"]) }),
            params: params,
            opts: opts
          )
        end

        # Updates a test mode created OutboundTransfer with tracking details. The OutboundTransfer must not be cancelable, and cannot be in the canceled or failed states.
        def self.update(outbound_transfer, params = {}, opts = {})
          request_stripe_object(
            method: :post,
            path: format("/v1/test_helpers/treasury/outbound_transfers/%<outbound_transfer>s", { outbound_transfer: CGI.escape(outbound_transfer) }),
            params: params,
            opts: opts
          )
        end

        # Updates a test mode created OutboundTransfer with tracking details. The OutboundTransfer must not be cancelable, and cannot be in the canceled or failed states.
        def update(params = {}, opts = {})
          @resource.request_stripe_object(
            method: :post,
            path: format("/v1/test_helpers/treasury/outbound_transfers/%<outbound_transfer>s", { outbound_transfer: CGI.escape(@resource["id"]) }),
            params: params,
            opts: opts
          )
        end
      end

      def self.inner_class_types
        @inner_class_types = {
          destination_payment_method_details: DestinationPaymentMethodDetails,
          returned_details: ReturnedDetails,
          status_transitions: StatusTransitions,
          tracking_details: TrackingDetails,
        }
      end

      def self.field_remappings
        @field_remappings = {}
      end
    end
  end
end
