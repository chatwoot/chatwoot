# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  module TestHelpers
    module Treasury
      class ReceivedDebitCreateParams < ::Stripe::RequestParams
        class InitiatingPaymentMethodDetails < ::Stripe::RequestParams
          class UsBankAccount < ::Stripe::RequestParams
            # The bank account holder's name.
            attr_accessor :account_holder_name
            # The bank account number.
            attr_accessor :account_number
            # The bank account's routing number.
            attr_accessor :routing_number

            def initialize(account_holder_name: nil, account_number: nil, routing_number: nil)
              @account_holder_name = account_holder_name
              @account_number = account_number
              @routing_number = routing_number
            end
          end
          # The source type.
          attr_accessor :type
          # Optional fields for `us_bank_account`.
          attr_accessor :us_bank_account

          def initialize(type: nil, us_bank_account: nil)
            @type = type
            @us_bank_account = us_bank_account
          end
        end
        # Amount (in cents) to be transferred.
        attr_accessor :amount
        # Three-letter [ISO currency code](https://www.iso.org/iso-4217-currency-codes.html), in lowercase. Must be a [supported currency](https://stripe.com/docs/currencies).
        attr_accessor :currency
        # An arbitrary string attached to the object. Often useful for displaying to users.
        attr_accessor :description
        # Specifies which fields in the response should be expanded.
        attr_accessor :expand
        # The FinancialAccount to pull funds from.
        attr_accessor :financial_account
        # Initiating payment method details for the object.
        attr_accessor :initiating_payment_method_details
        # Specifies the network rails to be used. If not set, will default to the PaymentMethod's preferred network. See the [docs](https://stripe.com/docs/treasury/money-movement/timelines) to learn more about money movement timelines for each network type.
        attr_accessor :network

        def initialize(
          amount: nil,
          currency: nil,
          description: nil,
          expand: nil,
          financial_account: nil,
          initiating_payment_method_details: nil,
          network: nil
        )
          @amount = amount
          @currency = currency
          @description = description
          @expand = expand
          @financial_account = financial_account
          @initiating_payment_method_details = initiating_payment_method_details
          @network = network
        end
      end
    end
  end
end
