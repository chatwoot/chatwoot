# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  module Treasury
    class OutboundPaymentCreateParams < ::Stripe::RequestParams
      class DestinationPaymentMethodData < ::Stripe::RequestParams
        class BillingDetails < ::Stripe::RequestParams
          class Address < ::Stripe::RequestParams
            # City, district, suburb, town, or village.
            attr_accessor :city
            # Two-letter country code ([ISO 3166-1 alpha-2](https://en.wikipedia.org/wiki/ISO_3166-1_alpha-2)).
            attr_accessor :country
            # Address line 1, such as the street, PO Box, or company name.
            attr_accessor :line1
            # Address line 2, such as the apartment, suite, unit, or building.
            attr_accessor :line2
            # ZIP or postal code.
            attr_accessor :postal_code
            # State, county, province, or region.
            attr_accessor :state

            def initialize(
              city: nil,
              country: nil,
              line1: nil,
              line2: nil,
              postal_code: nil,
              state: nil
            )
              @city = city
              @country = country
              @line1 = line1
              @line2 = line2
              @postal_code = postal_code
              @state = state
            end
          end
          # Billing address.
          attr_accessor :address
          # Email address.
          attr_accessor :email
          # Full name.
          attr_accessor :name
          # Billing phone number (including extension).
          attr_accessor :phone

          def initialize(address: nil, email: nil, name: nil, phone: nil)
            @address = address
            @email = email
            @name = name
            @phone = phone
          end
        end

        class UsBankAccount < ::Stripe::RequestParams
          # Account holder type: individual or company.
          attr_accessor :account_holder_type
          # Account number of the bank account.
          attr_accessor :account_number
          # Account type: checkings or savings. Defaults to checking if omitted.
          attr_accessor :account_type
          # The ID of a Financial Connections Account to use as a payment method.
          attr_accessor :financial_connections_account
          # Routing number of the bank account.
          attr_accessor :routing_number

          def initialize(
            account_holder_type: nil,
            account_number: nil,
            account_type: nil,
            financial_connections_account: nil,
            routing_number: nil
          )
            @account_holder_type = account_holder_type
            @account_number = account_number
            @account_type = account_type
            @financial_connections_account = financial_connections_account
            @routing_number = routing_number
          end
        end
        # Billing information associated with the PaymentMethod that may be used or required by particular types of payment methods.
        attr_accessor :billing_details
        # Required if type is set to `financial_account`. The FinancialAccount ID to send funds to.
        attr_accessor :financial_account
        # Set of [key-value pairs](https://stripe.com/docs/api/metadata) that you can attach to an object. This can be useful for storing additional information about the object in a structured format. Individual keys can be unset by posting an empty value to them. All keys can be unset by posting an empty value to `metadata`.
        attr_accessor :metadata
        # The type of the PaymentMethod. An additional hash is included on the PaymentMethod with a name matching this value. It contains additional information specific to the PaymentMethod type.
        attr_accessor :type
        # Required hash if type is set to `us_bank_account`.
        attr_accessor :us_bank_account

        def initialize(
          billing_details: nil,
          financial_account: nil,
          metadata: nil,
          type: nil,
          us_bank_account: nil
        )
          @billing_details = billing_details
          @financial_account = financial_account
          @metadata = metadata
          @type = type
          @us_bank_account = us_bank_account
        end
      end

      class DestinationPaymentMethodOptions < ::Stripe::RequestParams
        class UsBankAccount < ::Stripe::RequestParams
          # Specifies the network rails to be used. If not set, will default to the PaymentMethod's preferred network. See the [docs](https://stripe.com/docs/treasury/money-movement/timelines) to learn more about money movement timelines for each network type.
          attr_accessor :network

          def initialize(network: nil)
            @network = network
          end
        end
        # Optional fields for `us_bank_account`.
        attr_accessor :us_bank_account

        def initialize(us_bank_account: nil)
          @us_bank_account = us_bank_account
        end
      end

      class EndUserDetails < ::Stripe::RequestParams
        # IP address of the user initiating the OutboundPayment. Must be supplied if `present` is set to `true`.
        attr_accessor :ip_address
        # `True` if the OutboundPayment creation request is being made on behalf of an end user by a platform. Otherwise, `false`.
        attr_accessor :present

        def initialize(ip_address: nil, present: nil)
          @ip_address = ip_address
          @present = present
        end
      end
      # Amount (in cents) to be transferred.
      attr_accessor :amount
      # Three-letter [ISO currency code](https://www.iso.org/iso-4217-currency-codes.html), in lowercase. Must be a [supported currency](https://stripe.com/docs/currencies).
      attr_accessor :currency
      # ID of the customer to whom the OutboundPayment is sent. Must match the Customer attached to the `destination_payment_method` passed in.
      attr_accessor :customer
      # An arbitrary string attached to the object. Often useful for displaying to users.
      attr_accessor :description
      # The PaymentMethod to use as the payment instrument for the OutboundPayment. Exclusive with `destination_payment_method_data`.
      attr_accessor :destination_payment_method
      # Hash used to generate the PaymentMethod to be used for this OutboundPayment. Exclusive with `destination_payment_method`.
      attr_accessor :destination_payment_method_data
      # Payment method-specific configuration for this OutboundPayment.
      attr_accessor :destination_payment_method_options
      # End user details.
      attr_accessor :end_user_details
      # Specifies which fields in the response should be expanded.
      attr_accessor :expand
      # The FinancialAccount to pull funds from.
      attr_accessor :financial_account
      # Set of [key-value pairs](https://stripe.com/docs/api/metadata) that you can attach to an object. This can be useful for storing additional information about the object in a structured format. Individual keys can be unset by posting an empty value to them. All keys can be unset by posting an empty value to `metadata`.
      attr_accessor :metadata
      # The description that appears on the receiving end for this OutboundPayment (for example, bank statement for external bank transfer). Maximum 10 characters for `ach` payments, 140 characters for `us_domestic_wire` payments, or 500 characters for `stripe` network transfers. The default value is "payment".
      attr_accessor :statement_descriptor

      def initialize(
        amount: nil,
        currency: nil,
        customer: nil,
        description: nil,
        destination_payment_method: nil,
        destination_payment_method_data: nil,
        destination_payment_method_options: nil,
        end_user_details: nil,
        expand: nil,
        financial_account: nil,
        metadata: nil,
        statement_descriptor: nil
      )
        @amount = amount
        @currency = currency
        @customer = customer
        @description = description
        @destination_payment_method = destination_payment_method
        @destination_payment_method_data = destination_payment_method_data
        @destination_payment_method_options = destination_payment_method_options
        @end_user_details = end_user_details
        @expand = expand
        @financial_account = financial_account
        @metadata = metadata
        @statement_descriptor = statement_descriptor
      end
    end
  end
end
