# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  # A Mandate is a record of the permission that your customer gives you to debit their payment method.
  class Mandate < APIResource
    OBJECT_NAME = "mandate"
    def self.object_name
      "mandate"
    end

    class CustomerAcceptance < ::Stripe::StripeObject
      class Offline < ::Stripe::StripeObject
        def self.inner_class_types
          @inner_class_types = {}
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end

      class Online < ::Stripe::StripeObject
        # The customer accepts the mandate from this IP address.
        attr_reader :ip_address
        # The customer accepts the mandate using the user agent of the browser.
        attr_reader :user_agent

        def self.inner_class_types
          @inner_class_types = {}
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end
      # The time that the customer accepts the mandate.
      attr_reader :accepted_at
      # Attribute for field offline
      attr_reader :offline
      # Attribute for field online
      attr_reader :online
      # The mandate includes the type of customer acceptance information, such as: `online` or `offline`.
      attr_reader :type

      def self.inner_class_types
        @inner_class_types = { offline: Offline, online: Online }
      end

      def self.field_remappings
        @field_remappings = {}
      end
    end

    class MultiUse < ::Stripe::StripeObject
      def self.inner_class_types
        @inner_class_types = {}
      end

      def self.field_remappings
        @field_remappings = {}
      end
    end

    class PaymentMethodDetails < ::Stripe::StripeObject
      class AcssDebit < ::Stripe::StripeObject
        # List of Stripe products where this mandate can be selected automatically.
        attr_reader :default_for
        # Description of the interval. Only required if the 'payment_schedule' parameter is 'interval' or 'combined'.
        attr_reader :interval_description
        # Payment schedule for the mandate.
        attr_reader :payment_schedule
        # Transaction type of the mandate.
        attr_reader :transaction_type

        def self.inner_class_types
          @inner_class_types = {}
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end

      class AmazonPay < ::Stripe::StripeObject
        def self.inner_class_types
          @inner_class_types = {}
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end

      class AuBecsDebit < ::Stripe::StripeObject
        # The URL of the mandate. This URL generally contains sensitive information about the customer and should be shared with them exclusively.
        attr_reader :url

        def self.inner_class_types
          @inner_class_types = {}
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end

      class BacsDebit < ::Stripe::StripeObject
        # The status of the mandate on the Bacs network. Can be one of `pending`, `revoked`, `refused`, or `accepted`.
        attr_reader :network_status
        # The unique reference identifying the mandate on the Bacs network.
        attr_reader :reference
        # When the mandate is revoked on the Bacs network this field displays the reason for the revocation.
        attr_reader :revocation_reason
        # The URL that will contain the mandate that the customer has signed.
        attr_reader :url

        def self.inner_class_types
          @inner_class_types = {}
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end

      class Card < ::Stripe::StripeObject
        def self.inner_class_types
          @inner_class_types = {}
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end

      class Cashapp < ::Stripe::StripeObject
        def self.inner_class_types
          @inner_class_types = {}
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end

      class KakaoPay < ::Stripe::StripeObject
        def self.inner_class_types
          @inner_class_types = {}
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end

      class Klarna < ::Stripe::StripeObject
        def self.inner_class_types
          @inner_class_types = {}
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end

      class KrCard < ::Stripe::StripeObject
        def self.inner_class_types
          @inner_class_types = {}
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end

      class Link < ::Stripe::StripeObject
        def self.inner_class_types
          @inner_class_types = {}
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end

      class NaverPay < ::Stripe::StripeObject
        def self.inner_class_types
          @inner_class_types = {}
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end

      class NzBankAccount < ::Stripe::StripeObject
        def self.inner_class_types
          @inner_class_types = {}
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end

      class Paypal < ::Stripe::StripeObject
        # The PayPal Billing Agreement ID (BAID). This is an ID generated by PayPal which represents the mandate between the merchant and the customer.
        attr_reader :billing_agreement_id
        # PayPal account PayerID. This identifier uniquely identifies the PayPal customer.
        attr_reader :payer_id

        def self.inner_class_types
          @inner_class_types = {}
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end

      class RevolutPay < ::Stripe::StripeObject
        def self.inner_class_types
          @inner_class_types = {}
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end

      class SepaDebit < ::Stripe::StripeObject
        # The unique reference of the mandate.
        attr_reader :reference
        # The URL of the mandate. This URL generally contains sensitive information about the customer and should be shared with them exclusively.
        attr_reader :url

        def self.inner_class_types
          @inner_class_types = {}
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end

      class UsBankAccount < ::Stripe::StripeObject
        # Mandate collection method
        attr_reader :collection_method

        def self.inner_class_types
          @inner_class_types = {}
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end
      # Attribute for field acss_debit
      attr_reader :acss_debit
      # Attribute for field amazon_pay
      attr_reader :amazon_pay
      # Attribute for field au_becs_debit
      attr_reader :au_becs_debit
      # Attribute for field bacs_debit
      attr_reader :bacs_debit
      # Attribute for field card
      attr_reader :card
      # Attribute for field cashapp
      attr_reader :cashapp
      # Attribute for field kakao_pay
      attr_reader :kakao_pay
      # Attribute for field klarna
      attr_reader :klarna
      # Attribute for field kr_card
      attr_reader :kr_card
      # Attribute for field link
      attr_reader :link
      # Attribute for field naver_pay
      attr_reader :naver_pay
      # Attribute for field nz_bank_account
      attr_reader :nz_bank_account
      # Attribute for field paypal
      attr_reader :paypal
      # Attribute for field revolut_pay
      attr_reader :revolut_pay
      # Attribute for field sepa_debit
      attr_reader :sepa_debit
      # This mandate corresponds with a specific payment method type. The `payment_method_details` includes an additional hash with the same name and contains mandate information that's specific to that payment method.
      attr_reader :type
      # Attribute for field us_bank_account
      attr_reader :us_bank_account

      def self.inner_class_types
        @inner_class_types = {
          acss_debit: AcssDebit,
          amazon_pay: AmazonPay,
          au_becs_debit: AuBecsDebit,
          bacs_debit: BacsDebit,
          card: Card,
          cashapp: Cashapp,
          kakao_pay: KakaoPay,
          klarna: Klarna,
          kr_card: KrCard,
          link: Link,
          naver_pay: NaverPay,
          nz_bank_account: NzBankAccount,
          paypal: Paypal,
          revolut_pay: RevolutPay,
          sepa_debit: SepaDebit,
          us_bank_account: UsBankAccount,
        }
      end

      def self.field_remappings
        @field_remappings = {}
      end
    end

    class SingleUse < ::Stripe::StripeObject
      # The amount of the payment on a single use mandate.
      attr_reader :amount
      # The currency of the payment on a single use mandate.
      attr_reader :currency

      def self.inner_class_types
        @inner_class_types = {}
      end

      def self.field_remappings
        @field_remappings = {}
      end
    end
    # Attribute for field customer_acceptance
    attr_reader :customer_acceptance
    # Unique identifier for the object.
    attr_reader :id
    # Has the value `true` if the object exists in live mode or the value `false` if the object exists in test mode.
    attr_reader :livemode
    # Attribute for field multi_use
    attr_reader :multi_use
    # String representing the object's type. Objects of the same type share the same value.
    attr_reader :object
    # The account (if any) that the mandate is intended for.
    attr_reader :on_behalf_of
    # ID of the payment method associated with this mandate.
    attr_reader :payment_method
    # Attribute for field payment_method_details
    attr_reader :payment_method_details
    # Attribute for field single_use
    attr_reader :single_use
    # The mandate status indicates whether or not you can use it to initiate a payment.
    attr_reader :status
    # The type of the mandate.
    attr_reader :type

    def self.inner_class_types
      @inner_class_types = {
        customer_acceptance: CustomerAcceptance,
        multi_use: MultiUse,
        payment_method_details: PaymentMethodDetails,
        single_use: SingleUse,
      }
    end

    def self.field_remappings
      @field_remappings = {}
    end
  end
end
