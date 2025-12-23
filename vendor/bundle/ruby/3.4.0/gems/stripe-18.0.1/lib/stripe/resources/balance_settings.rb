# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  # Options for customizing account balances and payout settings for a Stripe platform's connected accounts.
  class BalanceSettings < SingletonAPIResource
    include Stripe::APIOperations::SingletonSave

    OBJECT_NAME = "balance_settings"
    def self.object_name
      "balance_settings"
    end

    class Payments < ::Stripe::StripeObject
      class Payouts < ::Stripe::StripeObject
        class Schedule < ::Stripe::StripeObject
          # How frequently funds will be paid out. One of `manual` (payouts only created via API call), `daily`, `weekly`, or `monthly`.
          attr_reader :interval
          # The day of the month funds will be paid out. Only shown if `interval` is monthly. Payouts scheduled between the 29th and 31st of the month are sent on the last day of shorter months.
          attr_reader :monthly_payout_days
          # The days of the week when available funds are paid out, specified as an array, for example, [`monday`, `tuesday`]. Only shown if `interval` is weekly.
          attr_reader :weekly_payout_days

          def self.inner_class_types
            @inner_class_types = {}
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end
        # The minimum balance amount to retain per currency after automatic payouts. Only funds that exceed these amounts are paid out. Learn more about the [minimum balances for automatic payouts](/payouts/minimum-balances-for-automatic-payouts).
        attr_reader :minimum_balance_by_currency
        # Details on when funds from charges are available, and when they are paid out to an external account. See our [Setting Bank and Debit Card Payouts](https://stripe.com/docs/connect/bank-transfers#payout-information) documentation for details.
        attr_reader :schedule
        # The text that appears on the bank account statement for payouts. If not set, this defaults to the platform's bank descriptor as set in the Dashboard.
        attr_reader :statement_descriptor
        # Whether the funds in this account can be paid out.
        attr_reader :status

        def self.inner_class_types
          @inner_class_types = { schedule: Schedule }
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end

      class SettlementTiming < ::Stripe::StripeObject
        # The number of days charge funds are held before becoming available.
        attr_reader :delay_days
        # The number of days charge funds are held before becoming available. If present, overrides the default, or minimum available, for the account.
        attr_reader :delay_days_override

        def self.inner_class_types
          @inner_class_types = {}
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end
      # A Boolean indicating if Stripe should try to reclaim negative balances from an attached bank account. See [Understanding Connect account balances](/connect/account-balances) for details. The default value is `false` when [controller.requirement_collection](/api/accounts/object#account_object-controller-requirement_collection) is `application`, which includes Custom accounts, otherwise `true`.
      attr_reader :debit_negative_balances
      # Settings specific to the account's payouts.
      attr_reader :payouts
      # Attribute for field settlement_timing
      attr_reader :settlement_timing

      def self.inner_class_types
        @inner_class_types = { payouts: Payouts, settlement_timing: SettlementTiming }
      end

      def self.field_remappings
        @field_remappings = {}
      end
    end
    # String representing the object's type. Objects of the same type share the same value.
    attr_reader :object
    # Attribute for field payments
    attr_reader :payments

    def self.inner_class_types
      @inner_class_types = { payments: Payments }
    end

    def self.field_remappings
      @field_remappings = {}
    end
  end
end
