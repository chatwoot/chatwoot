# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  module Treasury
    # Use [OutboundPayments](https://docs.stripe.com/docs/treasury/moving-money/financial-accounts/out-of/outbound-payments) to send funds to another party's external bank account or [FinancialAccount](https://stripe.com/docs/api#financial_accounts). To send money to an account belonging to the same user, use an [OutboundTransfer](https://stripe.com/docs/api#outbound_transfers).
    #
    # Simulate OutboundPayment state changes with the `/v1/test_helpers/treasury/outbound_payments` endpoints. These methods can only be called on test mode objects.
    #
    # Related guide: [Moving money with Treasury using OutboundPayment objects](https://docs.stripe.com/docs/treasury/moving-money/financial-accounts/out-of/outbound-payments)
    class OutboundPayment < APIResource
      extend Stripe::APIOperations::Create
      extend Stripe::APIOperations::List

      OBJECT_NAME = "treasury.outbound_payment"
      def self.object_name
        "treasury.outbound_payment"
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
        # The type of the payment method used in the OutboundPayment.
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

      class EndUserDetails < ::Stripe::StripeObject
        # IP address of the user initiating the OutboundPayment. Set if `present` is set to `true`. IP address collection is required for risk and compliance reasons. This will be used to help determine if the OutboundPayment is authorized or should be blocked.
        attr_reader :ip_address
        # `true` if the OutboundPayment creation request is being made on behalf of an end user by a platform. Otherwise, `false`.
        attr_reader :present

        def self.inner_class_types
          @inner_class_types = {}
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
        # Timestamp describing when an OutboundPayment changed status to `canceled`.
        attr_reader :canceled_at
        # Timestamp describing when an OutboundPayment changed status to `failed`.
        attr_reader :failed_at
        # Timestamp describing when an OutboundPayment changed status to `posted`.
        attr_reader :posted_at
        # Timestamp describing when an OutboundPayment changed status to `returned`.
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
          # ACH trace ID of the OutboundPayment for payments sent over the `ach` network.
          attr_reader :trace_id

          def self.inner_class_types
            @inner_class_types = {}
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end

        class UsDomesticWire < ::Stripe::StripeObject
          # CHIPS System Sequence Number (SSN) of the OutboundPayment for payments sent over the `us_domestic_wire` network.
          attr_reader :chips
          # IMAD of the OutboundPayment for payments sent over the `us_domestic_wire` network.
          attr_reader :imad
          # OMAD of the OutboundPayment for payments sent over the `us_domestic_wire` network.
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
      # ID of the [customer](https://stripe.com/docs/api/customers) to whom an OutboundPayment is sent.
      attr_reader :customer
      # An arbitrary string attached to the object. Often useful for displaying to users.
      attr_reader :description
      # The PaymentMethod via which an OutboundPayment is sent. This field can be empty if the OutboundPayment was created using `destination_payment_method_data`.
      attr_reader :destination_payment_method
      # Details about the PaymentMethod for an OutboundPayment.
      attr_reader :destination_payment_method_details
      # Details about the end user.
      attr_reader :end_user_details
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
      # Details about a returned OutboundPayment. Only set when the status is `returned`.
      attr_reader :returned_details
      # The description that appears on the receiving end for an OutboundPayment (for example, bank statement for external bank transfer).
      attr_reader :statement_descriptor
      # Current status of the OutboundPayment: `processing`, `failed`, `posted`, `returned`, `canceled`. An OutboundPayment is `processing` if it has been created and is pending. The status changes to `posted` once the OutboundPayment has been "confirmed" and funds have left the account, or to `failed` or `canceled`. If an OutboundPayment fails to arrive at its destination, its status will change to `returned`.
      attr_reader :status
      # Attribute for field status_transitions
      attr_reader :status_transitions
      # Details about network-specific tracking information if available.
      attr_reader :tracking_details
      # The Transaction associated with this object.
      attr_reader :transaction

      # Cancel an OutboundPayment.
      def cancel(params = {}, opts = {})
        request_stripe_object(
          method: :post,
          path: format("/v1/treasury/outbound_payments/%<id>s/cancel", { id: CGI.escape(self["id"]) }),
          params: params,
          opts: opts
        )
      end

      # Cancel an OutboundPayment.
      def self.cancel(id, params = {}, opts = {})
        request_stripe_object(
          method: :post,
          path: format("/v1/treasury/outbound_payments/%<id>s/cancel", { id: CGI.escape(id) }),
          params: params,
          opts: opts
        )
      end

      # Creates an OutboundPayment.
      def self.create(params = {}, opts = {})
        request_stripe_object(
          method: :post,
          path: "/v1/treasury/outbound_payments",
          params: params,
          opts: opts
        )
      end

      # Returns a list of OutboundPayments sent from the specified FinancialAccount.
      def self.list(params = {}, opts = {})
        request_stripe_object(
          method: :get,
          path: "/v1/treasury/outbound_payments",
          params: params,
          opts: opts
        )
      end

      def test_helpers
        TestHelpers.new(self)
      end

      class TestHelpers < APIResourceTestHelpers
        RESOURCE_CLASS = OutboundPayment
        def self.resource_class
          "OutboundPayment"
        end

        # Transitions a test mode created OutboundPayment to the failed status. The OutboundPayment must already be in the processing state.
        def self.fail(id, params = {}, opts = {})
          request_stripe_object(
            method: :post,
            path: format("/v1/test_helpers/treasury/outbound_payments/%<id>s/fail", { id: CGI.escape(id) }),
            params: params,
            opts: opts
          )
        end

        # Transitions a test mode created OutboundPayment to the failed status. The OutboundPayment must already be in the processing state.
        def fail(params = {}, opts = {})
          @resource.request_stripe_object(
            method: :post,
            path: format("/v1/test_helpers/treasury/outbound_payments/%<id>s/fail", { id: CGI.escape(@resource["id"]) }),
            params: params,
            opts: opts
          )
        end

        # Transitions a test mode created OutboundPayment to the posted status. The OutboundPayment must already be in the processing state.
        def self.post(id, params = {}, opts = {})
          request_stripe_object(
            method: :post,
            path: format("/v1/test_helpers/treasury/outbound_payments/%<id>s/post", { id: CGI.escape(id) }),
            params: params,
            opts: opts
          )
        end

        # Transitions a test mode created OutboundPayment to the posted status. The OutboundPayment must already be in the processing state.
        def post(params = {}, opts = {})
          @resource.request_stripe_object(
            method: :post,
            path: format("/v1/test_helpers/treasury/outbound_payments/%<id>s/post", { id: CGI.escape(@resource["id"]) }),
            params: params,
            opts: opts
          )
        end

        # Transitions a test mode created OutboundPayment to the returned status. The OutboundPayment must already be in the processing state.
        def self.return_outbound_payment(id, params = {}, opts = {})
          request_stripe_object(
            method: :post,
            path: format("/v1/test_helpers/treasury/outbound_payments/%<id>s/return", { id: CGI.escape(id) }),
            params: params,
            opts: opts
          )
        end

        # Transitions a test mode created OutboundPayment to the returned status. The OutboundPayment must already be in the processing state.
        def return_outbound_payment(params = {}, opts = {})
          @resource.request_stripe_object(
            method: :post,
            path: format("/v1/test_helpers/treasury/outbound_payments/%<id>s/return", { id: CGI.escape(@resource["id"]) }),
            params: params,
            opts: opts
          )
        end

        # Updates a test mode created OutboundPayment with tracking details. The OutboundPayment must not be cancelable, and cannot be in the canceled or failed states.
        def self.update(id, params = {}, opts = {})
          request_stripe_object(
            method: :post,
            path: format("/v1/test_helpers/treasury/outbound_payments/%<id>s", { id: CGI.escape(id) }),
            params: params,
            opts: opts
          )
        end

        # Updates a test mode created OutboundPayment with tracking details. The OutboundPayment must not be cancelable, and cannot be in the canceled or failed states.
        def update(params = {}, opts = {})
          @resource.request_stripe_object(
            method: :post,
            path: format("/v1/test_helpers/treasury/outbound_payments/%<id>s", { id: CGI.escape(@resource["id"]) }),
            params: params,
            opts: opts
          )
        end
      end

      def self.inner_class_types
        @inner_class_types = {
          destination_payment_method_details: DestinationPaymentMethodDetails,
          end_user_details: EndUserDetails,
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
