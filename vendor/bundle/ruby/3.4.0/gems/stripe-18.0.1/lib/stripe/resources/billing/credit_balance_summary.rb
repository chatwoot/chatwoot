# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  module Billing
    # Indicates the billing credit balance for billing credits granted to a customer.
    class CreditBalanceSummary < SingletonAPIResource
      OBJECT_NAME = "billing.credit_balance_summary"
      def self.object_name
        "billing.credit_balance_summary"
      end

      class Balance < ::Stripe::StripeObject
        class AvailableBalance < ::Stripe::StripeObject
          class Monetary < ::Stripe::StripeObject
            # Three-letter [ISO currency code](https://www.iso.org/iso-4217-currency-codes.html), in lowercase. Must be a [supported currency](https://stripe.com/docs/currencies).
            attr_reader :currency
            # A positive integer representing the amount.
            attr_reader :value

            def self.inner_class_types
              @inner_class_types = {}
            end

            def self.field_remappings
              @field_remappings = {}
            end
          end
          # The monetary amount.
          attr_reader :monetary
          # The type of this amount. We currently only support `monetary` billing credits.
          attr_reader :type

          def self.inner_class_types
            @inner_class_types = { monetary: Monetary }
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end

        class LedgerBalance < ::Stripe::StripeObject
          class Monetary < ::Stripe::StripeObject
            # Three-letter [ISO currency code](https://www.iso.org/iso-4217-currency-codes.html), in lowercase. Must be a [supported currency](https://stripe.com/docs/currencies).
            attr_reader :currency
            # A positive integer representing the amount.
            attr_reader :value

            def self.inner_class_types
              @inner_class_types = {}
            end

            def self.field_remappings
              @field_remappings = {}
            end
          end
          # The monetary amount.
          attr_reader :monetary
          # The type of this amount. We currently only support `monetary` billing credits.
          attr_reader :type

          def self.inner_class_types
            @inner_class_types = { monetary: Monetary }
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end
        # Attribute for field available_balance
        attr_reader :available_balance
        # Attribute for field ledger_balance
        attr_reader :ledger_balance

        def self.inner_class_types
          @inner_class_types = { available_balance: AvailableBalance, ledger_balance: LedgerBalance }
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end
      # The billing credit balances. One entry per credit grant currency. If a customer only has credit grants in a single currency, then this will have a single balance entry.
      attr_reader :balances
      # The customer the balance is for.
      attr_reader :customer
      # Has the value `true` if the object exists in live mode or the value `false` if the object exists in test mode.
      attr_reader :livemode
      # String representing the object's type. Objects of the same type share the same value.
      attr_reader :object

      def self.inner_class_types
        @inner_class_types = { balances: Balance }
      end

      def self.field_remappings
        @field_remappings = {}
      end
    end
  end
end
