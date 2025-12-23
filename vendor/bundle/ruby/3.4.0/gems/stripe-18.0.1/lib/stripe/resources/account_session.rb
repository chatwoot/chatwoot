# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  # An AccountSession allows a Connect platform to grant access to a connected account in Connect embedded components.
  #
  # We recommend that you create an AccountSession each time you need to display an embedded component
  # to your user. Do not save AccountSessions to your database as they expire relatively
  # quickly, and cannot be used more than once.
  #
  # Related guide: [Connect embedded components](https://stripe.com/docs/connect/get-started-connect-embedded-components)
  class AccountSession < APIResource
    extend Stripe::APIOperations::Create

    OBJECT_NAME = "account_session"
    def self.object_name
      "account_session"
    end

    class Components < ::Stripe::StripeObject
      class AccountManagement < ::Stripe::StripeObject
        class Features < ::Stripe::StripeObject
          # Whether Stripe user authentication is disabled. This value can only be `true` for accounts where `controller.requirement_collection` is `application` for the account. The default value is the opposite of the `external_account_collection` value. For example, if you don't set `external_account_collection`, it defaults to `true` and `disable_stripe_user_authentication` defaults to `false`.
          attr_reader :disable_stripe_user_authentication
          # Whether external account collection is enabled. This feature can only be `false` for accounts where you’re responsible for collecting updated information when requirements are due or change, like Custom accounts. The default value for this feature is `true`.
          attr_reader :external_account_collection

          def self.inner_class_types
            @inner_class_types = {}
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end
        # Whether the embedded component is enabled.
        attr_reader :enabled
        # Attribute for field features
        attr_reader :features

        def self.inner_class_types
          @inner_class_types = { features: Features }
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end

      class AccountOnboarding < ::Stripe::StripeObject
        class Features < ::Stripe::StripeObject
          # Whether Stripe user authentication is disabled. This value can only be `true` for accounts where `controller.requirement_collection` is `application` for the account. The default value is the opposite of the `external_account_collection` value. For example, if you don't set `external_account_collection`, it defaults to `true` and `disable_stripe_user_authentication` defaults to `false`.
          attr_reader :disable_stripe_user_authentication
          # Whether external account collection is enabled. This feature can only be `false` for accounts where you’re responsible for collecting updated information when requirements are due or change, like Custom accounts. The default value for this feature is `true`.
          attr_reader :external_account_collection

          def self.inner_class_types
            @inner_class_types = {}
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end
        # Whether the embedded component is enabled.
        attr_reader :enabled
        # Attribute for field features
        attr_reader :features

        def self.inner_class_types
          @inner_class_types = { features: Features }
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end

      class Balances < ::Stripe::StripeObject
        class Features < ::Stripe::StripeObject
          # Whether Stripe user authentication is disabled. This value can only be `true` for accounts where `controller.requirement_collection` is `application` for the account. The default value is the opposite of the `external_account_collection` value. For example, if you don't set `external_account_collection`, it defaults to `true` and `disable_stripe_user_authentication` defaults to `false`.
          attr_reader :disable_stripe_user_authentication
          # Whether to allow payout schedule to be changed. Defaults to `true` when `controller.losses.payments` is set to `stripe` for the account, otherwise `false`.
          attr_reader :edit_payout_schedule
          # Whether external account collection is enabled. This feature can only be `false` for accounts where you’re responsible for collecting updated information when requirements are due or change, like Custom accounts. The default value for this feature is `true`.
          attr_reader :external_account_collection
          # Whether to allow creation of instant payouts. Defaults to `true` when `controller.losses.payments` is set to `stripe` for the account, otherwise `false`.
          attr_reader :instant_payouts
          # Whether to allow creation of standard payouts. Defaults to `true` when `controller.losses.payments` is set to `stripe` for the account, otherwise `false`.
          attr_reader :standard_payouts

          def self.inner_class_types
            @inner_class_types = {}
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end
        # Whether the embedded component is enabled.
        attr_reader :enabled
        # Attribute for field features
        attr_reader :features

        def self.inner_class_types
          @inner_class_types = { features: Features }
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end

      class DisputesList < ::Stripe::StripeObject
        class Features < ::Stripe::StripeObject
          # Whether to allow capturing and cancelling payment intents. This is `true` by default.
          attr_reader :capture_payments
          # Whether connected accounts can manage destination charges that are created on behalf of them. This is `false` by default.
          attr_reader :destination_on_behalf_of_charge_management
          # Whether responding to disputes is enabled, including submitting evidence and accepting disputes. This is `true` by default.
          attr_reader :dispute_management
          # Whether sending refunds is enabled. This is `true` by default.
          attr_reader :refund_management

          def self.inner_class_types
            @inner_class_types = {}
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end
        # Whether the embedded component is enabled.
        attr_reader :enabled
        # Attribute for field features
        attr_reader :features

        def self.inner_class_types
          @inner_class_types = { features: Features }
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end

      class Documents < ::Stripe::StripeObject
        class Features < ::Stripe::StripeObject
          def self.inner_class_types
            @inner_class_types = {}
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end
        # Whether the embedded component is enabled.
        attr_reader :enabled
        # Attribute for field features
        attr_reader :features

        def self.inner_class_types
          @inner_class_types = { features: Features }
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end

      class FinancialAccount < ::Stripe::StripeObject
        class Features < ::Stripe::StripeObject
          # Whether Stripe user authentication is disabled. This value can only be `true` for accounts where `controller.requirement_collection` is `application` for the account. The default value is the opposite of the `external_account_collection` value. For example, if you don't set `external_account_collection`, it defaults to `true` and `disable_stripe_user_authentication` defaults to `false`.
          attr_reader :disable_stripe_user_authentication
          # Whether external account collection is enabled. This feature can only be `false` for accounts where you’re responsible for collecting updated information when requirements are due or change, like Custom accounts. The default value for this feature is `true`.
          attr_reader :external_account_collection
          # Whether to allow sending money.
          attr_reader :send_money
          # Whether to allow transferring balance.
          attr_reader :transfer_balance

          def self.inner_class_types
            @inner_class_types = {}
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end
        # Whether the embedded component is enabled.
        attr_reader :enabled
        # Attribute for field features
        attr_reader :features

        def self.inner_class_types
          @inner_class_types = { features: Features }
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end

      class FinancialAccountTransactions < ::Stripe::StripeObject
        class Features < ::Stripe::StripeObject
          # Whether to allow card spend dispute management features.
          attr_reader :card_spend_dispute_management

          def self.inner_class_types
            @inner_class_types = {}
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end
        # Whether the embedded component is enabled.
        attr_reader :enabled
        # Attribute for field features
        attr_reader :features

        def self.inner_class_types
          @inner_class_types = { features: Features }
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end

      class InstantPayoutsPromotion < ::Stripe::StripeObject
        class Features < ::Stripe::StripeObject
          # Whether Stripe user authentication is disabled. This value can only be `true` for accounts where `controller.requirement_collection` is `application` for the account. The default value is the opposite of the `external_account_collection` value. For example, if you don't set `external_account_collection`, it defaults to `true` and `disable_stripe_user_authentication` defaults to `false`.
          attr_reader :disable_stripe_user_authentication
          # Whether external account collection is enabled. This feature can only be `false` for accounts where you’re responsible for collecting updated information when requirements are due or change, like Custom accounts. The default value for this feature is `true`.
          attr_reader :external_account_collection
          # Whether to allow creation of instant payouts. Defaults to `true` when `controller.losses.payments` is set to `stripe` for the account, otherwise `false`.
          attr_reader :instant_payouts

          def self.inner_class_types
            @inner_class_types = {}
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end
        # Whether the embedded component is enabled.
        attr_reader :enabled
        # Attribute for field features
        attr_reader :features

        def self.inner_class_types
          @inner_class_types = { features: Features }
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end

      class IssuingCard < ::Stripe::StripeObject
        class Features < ::Stripe::StripeObject
          # Whether to allow card management features.
          attr_reader :card_management
          # Whether to allow card spend dispute management features.
          attr_reader :card_spend_dispute_management
          # Whether to allow cardholder management features.
          attr_reader :cardholder_management
          # Whether to allow spend control management features.
          attr_reader :spend_control_management

          def self.inner_class_types
            @inner_class_types = {}
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end
        # Whether the embedded component is enabled.
        attr_reader :enabled
        # Attribute for field features
        attr_reader :features

        def self.inner_class_types
          @inner_class_types = { features: Features }
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end

      class IssuingCardsList < ::Stripe::StripeObject
        class Features < ::Stripe::StripeObject
          # Whether to allow card management features.
          attr_reader :card_management
          # Whether to allow card spend dispute management features.
          attr_reader :card_spend_dispute_management
          # Whether to allow cardholder management features.
          attr_reader :cardholder_management
          # Whether Stripe user authentication is disabled. This value can only be `true` for accounts where `controller.requirement_collection` is `application` for the account. The default value is the opposite of the `external_account_collection` value. For example, if you don't set `external_account_collection`, it defaults to `true` and `disable_stripe_user_authentication` defaults to `false`.
          attr_reader :disable_stripe_user_authentication
          # Whether to allow spend control management features.
          attr_reader :spend_control_management

          def self.inner_class_types
            @inner_class_types = {}
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end
        # Whether the embedded component is enabled.
        attr_reader :enabled
        # Attribute for field features
        attr_reader :features

        def self.inner_class_types
          @inner_class_types = { features: Features }
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end

      class NotificationBanner < ::Stripe::StripeObject
        class Features < ::Stripe::StripeObject
          # Whether Stripe user authentication is disabled. This value can only be `true` for accounts where `controller.requirement_collection` is `application` for the account. The default value is the opposite of the `external_account_collection` value. For example, if you don't set `external_account_collection`, it defaults to `true` and `disable_stripe_user_authentication` defaults to `false`.
          attr_reader :disable_stripe_user_authentication
          # Whether external account collection is enabled. This feature can only be `false` for accounts where you’re responsible for collecting updated information when requirements are due or change, like Custom accounts. The default value for this feature is `true`.
          attr_reader :external_account_collection

          def self.inner_class_types
            @inner_class_types = {}
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end
        # Whether the embedded component is enabled.
        attr_reader :enabled
        # Attribute for field features
        attr_reader :features

        def self.inner_class_types
          @inner_class_types = { features: Features }
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end

      class PaymentDetails < ::Stripe::StripeObject
        class Features < ::Stripe::StripeObject
          # Whether to allow capturing and cancelling payment intents. This is `true` by default.
          attr_reader :capture_payments
          # Whether connected accounts can manage destination charges that are created on behalf of them. This is `false` by default.
          attr_reader :destination_on_behalf_of_charge_management
          # Whether responding to disputes is enabled, including submitting evidence and accepting disputes. This is `true` by default.
          attr_reader :dispute_management
          # Whether sending refunds is enabled. This is `true` by default.
          attr_reader :refund_management

          def self.inner_class_types
            @inner_class_types = {}
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end
        # Whether the embedded component is enabled.
        attr_reader :enabled
        # Attribute for field features
        attr_reader :features

        def self.inner_class_types
          @inner_class_types = { features: Features }
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end

      class PaymentDisputes < ::Stripe::StripeObject
        class Features < ::Stripe::StripeObject
          # Whether connected accounts can manage destination charges that are created on behalf of them. This is `false` by default.
          attr_reader :destination_on_behalf_of_charge_management
          # Whether responding to disputes is enabled, including submitting evidence and accepting disputes. This is `true` by default.
          attr_reader :dispute_management
          # Whether sending refunds is enabled. This is `true` by default.
          attr_reader :refund_management

          def self.inner_class_types
            @inner_class_types = {}
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end
        # Whether the embedded component is enabled.
        attr_reader :enabled
        # Attribute for field features
        attr_reader :features

        def self.inner_class_types
          @inner_class_types = { features: Features }
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end

      class Payments < ::Stripe::StripeObject
        class Features < ::Stripe::StripeObject
          # Whether to allow capturing and cancelling payment intents. This is `true` by default.
          attr_reader :capture_payments
          # Whether connected accounts can manage destination charges that are created on behalf of them. This is `false` by default.
          attr_reader :destination_on_behalf_of_charge_management
          # Whether responding to disputes is enabled, including submitting evidence and accepting disputes. This is `true` by default.
          attr_reader :dispute_management
          # Whether sending refunds is enabled. This is `true` by default.
          attr_reader :refund_management

          def self.inner_class_types
            @inner_class_types = {}
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end
        # Whether the embedded component is enabled.
        attr_reader :enabled
        # Attribute for field features
        attr_reader :features

        def self.inner_class_types
          @inner_class_types = { features: Features }
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end

      class PayoutDetails < ::Stripe::StripeObject
        class Features < ::Stripe::StripeObject
          def self.inner_class_types
            @inner_class_types = {}
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end
        # Whether the embedded component is enabled.
        attr_reader :enabled
        # Attribute for field features
        attr_reader :features

        def self.inner_class_types
          @inner_class_types = { features: Features }
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end

      class Payouts < ::Stripe::StripeObject
        class Features < ::Stripe::StripeObject
          # Whether Stripe user authentication is disabled. This value can only be `true` for accounts where `controller.requirement_collection` is `application` for the account. The default value is the opposite of the `external_account_collection` value. For example, if you don't set `external_account_collection`, it defaults to `true` and `disable_stripe_user_authentication` defaults to `false`.
          attr_reader :disable_stripe_user_authentication
          # Whether to allow payout schedule to be changed. Defaults to `true` when `controller.losses.payments` is set to `stripe` for the account, otherwise `false`.
          attr_reader :edit_payout_schedule
          # Whether external account collection is enabled. This feature can only be `false` for accounts where you’re responsible for collecting updated information when requirements are due or change, like Custom accounts. The default value for this feature is `true`.
          attr_reader :external_account_collection
          # Whether to allow creation of instant payouts. Defaults to `true` when `controller.losses.payments` is set to `stripe` for the account, otherwise `false`.
          attr_reader :instant_payouts
          # Whether to allow creation of standard payouts. Defaults to `true` when `controller.losses.payments` is set to `stripe` for the account, otherwise `false`.
          attr_reader :standard_payouts

          def self.inner_class_types
            @inner_class_types = {}
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end
        # Whether the embedded component is enabled.
        attr_reader :enabled
        # Attribute for field features
        attr_reader :features

        def self.inner_class_types
          @inner_class_types = { features: Features }
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end

      class PayoutsList < ::Stripe::StripeObject
        class Features < ::Stripe::StripeObject
          def self.inner_class_types
            @inner_class_types = {}
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end
        # Whether the embedded component is enabled.
        attr_reader :enabled
        # Attribute for field features
        attr_reader :features

        def self.inner_class_types
          @inner_class_types = { features: Features }
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end

      class TaxRegistrations < ::Stripe::StripeObject
        class Features < ::Stripe::StripeObject
          def self.inner_class_types
            @inner_class_types = {}
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end
        # Whether the embedded component is enabled.
        attr_reader :enabled
        # Attribute for field features
        attr_reader :features

        def self.inner_class_types
          @inner_class_types = { features: Features }
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end

      class TaxSettings < ::Stripe::StripeObject
        class Features < ::Stripe::StripeObject
          def self.inner_class_types
            @inner_class_types = {}
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end
        # Whether the embedded component is enabled.
        attr_reader :enabled
        # Attribute for field features
        attr_reader :features

        def self.inner_class_types
          @inner_class_types = { features: Features }
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end
      # Attribute for field account_management
      attr_reader :account_management
      # Attribute for field account_onboarding
      attr_reader :account_onboarding
      # Attribute for field balances
      attr_reader :balances
      # Attribute for field disputes_list
      attr_reader :disputes_list
      # Attribute for field documents
      attr_reader :documents
      # Attribute for field financial_account
      attr_reader :financial_account
      # Attribute for field financial_account_transactions
      attr_reader :financial_account_transactions
      # Attribute for field instant_payouts_promotion
      attr_reader :instant_payouts_promotion
      # Attribute for field issuing_card
      attr_reader :issuing_card
      # Attribute for field issuing_cards_list
      attr_reader :issuing_cards_list
      # Attribute for field notification_banner
      attr_reader :notification_banner
      # Attribute for field payment_details
      attr_reader :payment_details
      # Attribute for field payment_disputes
      attr_reader :payment_disputes
      # Attribute for field payments
      attr_reader :payments
      # Attribute for field payout_details
      attr_reader :payout_details
      # Attribute for field payouts
      attr_reader :payouts
      # Attribute for field payouts_list
      attr_reader :payouts_list
      # Attribute for field tax_registrations
      attr_reader :tax_registrations
      # Attribute for field tax_settings
      attr_reader :tax_settings

      def self.inner_class_types
        @inner_class_types = {
          account_management: AccountManagement,
          account_onboarding: AccountOnboarding,
          balances: Balances,
          disputes_list: DisputesList,
          documents: Documents,
          financial_account: FinancialAccount,
          financial_account_transactions: FinancialAccountTransactions,
          instant_payouts_promotion: InstantPayoutsPromotion,
          issuing_card: IssuingCard,
          issuing_cards_list: IssuingCardsList,
          notification_banner: NotificationBanner,
          payment_details: PaymentDetails,
          payment_disputes: PaymentDisputes,
          payments: Payments,
          payout_details: PayoutDetails,
          payouts: Payouts,
          payouts_list: PayoutsList,
          tax_registrations: TaxRegistrations,
          tax_settings: TaxSettings,
        }
      end

      def self.field_remappings
        @field_remappings = {}
      end
    end
    # The ID of the account the AccountSession was created for
    attr_reader :account
    # The client secret of this AccountSession. Used on the client to set up secure access to the given `account`.
    #
    # The client secret can be used to provide access to `account` from your frontend. It should not be stored, logged, or exposed to anyone other than the connected account. Make sure that you have TLS enabled on any page that includes the client secret.
    #
    # Refer to our docs to [setup Connect embedded components](https://stripe.com/docs/connect/get-started-connect-embedded-components) and learn about how `client_secret` should be handled.
    attr_reader :client_secret
    # Attribute for field components
    attr_reader :components
    # The timestamp at which this AccountSession will expire.
    attr_reader :expires_at
    # Has the value `true` if the object exists in live mode or the value `false` if the object exists in test mode.
    attr_reader :livemode
    # String representing the object's type. Objects of the same type share the same value.
    attr_reader :object

    # Creates a AccountSession object that includes a single-use token that the platform can use on their front-end to grant client-side API access.
    def self.create(params = {}, opts = {})
      request_stripe_object(method: :post, path: "/v1/account_sessions", params: params, opts: opts)
    end

    def self.inner_class_types
      @inner_class_types = { components: Components }
    end

    def self.field_remappings
      @field_remappings = {}
    end
  end
end
