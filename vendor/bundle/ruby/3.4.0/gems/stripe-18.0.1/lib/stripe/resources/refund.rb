# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  # Refund objects allow you to refund a previously created charge that isn't
  # refunded yet. Funds are refunded to the credit or debit card that's
  # initially charged.
  #
  # Related guide: [Refunds](https://stripe.com/docs/refunds)
  class Refund < APIResource
    extend Stripe::APIOperations::Create
    extend Stripe::APIOperations::List
    include Stripe::APIOperations::Save

    OBJECT_NAME = "refund"
    def self.object_name
      "refund"
    end

    class DestinationDetails < ::Stripe::StripeObject
      class Affirm < ::Stripe::StripeObject
        def self.inner_class_types
          @inner_class_types = {}
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end

      class AfterpayClearpay < ::Stripe::StripeObject
        def self.inner_class_types
          @inner_class_types = {}
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end

      class Alipay < ::Stripe::StripeObject
        def self.inner_class_types
          @inner_class_types = {}
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end

      class Alma < ::Stripe::StripeObject
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

      class AuBankTransfer < ::Stripe::StripeObject
        def self.inner_class_types
          @inner_class_types = {}
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end

      class Blik < ::Stripe::StripeObject
        # For refunds declined by the network, a decline code provided by the network which indicates the reason the refund failed.
        attr_reader :network_decline_code
        # The reference assigned to the refund.
        attr_reader :reference
        # Status of the reference on the refund. This can be `pending`, `available` or `unavailable`.
        attr_reader :reference_status

        def self.inner_class_types
          @inner_class_types = {}
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end

      class BrBankTransfer < ::Stripe::StripeObject
        # The reference assigned to the refund.
        attr_reader :reference
        # Status of the reference on the refund. This can be `pending`, `available` or `unavailable`.
        attr_reader :reference_status

        def self.inner_class_types
          @inner_class_types = {}
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end

      class Card < ::Stripe::StripeObject
        # Value of the reference number assigned to the refund.
        attr_reader :reference
        # Status of the reference number on the refund. This can be `pending`, `available` or `unavailable`.
        attr_reader :reference_status
        # Type of the reference number assigned to the refund.
        attr_reader :reference_type
        # The type of refund. This can be `refund`, `reversal`, or `pending`.
        attr_reader :type

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

      class Crypto < ::Stripe::StripeObject
        # The transaction hash of the refund.
        attr_reader :reference

        def self.inner_class_types
          @inner_class_types = {}
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end

      class CustomerCashBalance < ::Stripe::StripeObject
        def self.inner_class_types
          @inner_class_types = {}
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end

      class Eps < ::Stripe::StripeObject
        def self.inner_class_types
          @inner_class_types = {}
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end

      class EuBankTransfer < ::Stripe::StripeObject
        # The reference assigned to the refund.
        attr_reader :reference
        # Status of the reference on the refund. This can be `pending`, `available` or `unavailable`.
        attr_reader :reference_status

        def self.inner_class_types
          @inner_class_types = {}
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end

      class GbBankTransfer < ::Stripe::StripeObject
        # The reference assigned to the refund.
        attr_reader :reference
        # Status of the reference on the refund. This can be `pending`, `available` or `unavailable`.
        attr_reader :reference_status

        def self.inner_class_types
          @inner_class_types = {}
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end

      class Giropay < ::Stripe::StripeObject
        def self.inner_class_types
          @inner_class_types = {}
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end

      class Grabpay < ::Stripe::StripeObject
        def self.inner_class_types
          @inner_class_types = {}
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end

      class JpBankTransfer < ::Stripe::StripeObject
        # The reference assigned to the refund.
        attr_reader :reference
        # Status of the reference on the refund. This can be `pending`, `available` or `unavailable`.
        attr_reader :reference_status

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

      class MbWay < ::Stripe::StripeObject
        # The reference assigned to the refund.
        attr_reader :reference
        # Status of the reference on the refund. This can be `pending`, `available` or `unavailable`.
        attr_reader :reference_status

        def self.inner_class_types
          @inner_class_types = {}
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end

      class Multibanco < ::Stripe::StripeObject
        # The reference assigned to the refund.
        attr_reader :reference
        # Status of the reference on the refund. This can be `pending`, `available` or `unavailable`.
        attr_reader :reference_status

        def self.inner_class_types
          @inner_class_types = {}
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end

      class MxBankTransfer < ::Stripe::StripeObject
        # The reference assigned to the refund.
        attr_reader :reference
        # Status of the reference on the refund. This can be `pending`, `available` or `unavailable`.
        attr_reader :reference_status

        def self.inner_class_types
          @inner_class_types = {}
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end

      class NzBankTransfer < ::Stripe::StripeObject
        def self.inner_class_types
          @inner_class_types = {}
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end

      class P24 < ::Stripe::StripeObject
        # The reference assigned to the refund.
        attr_reader :reference
        # Status of the reference on the refund. This can be `pending`, `available` or `unavailable`.
        attr_reader :reference_status

        def self.inner_class_types
          @inner_class_types = {}
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end

      class Paynow < ::Stripe::StripeObject
        def self.inner_class_types
          @inner_class_types = {}
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end

      class Paypal < ::Stripe::StripeObject
        # For refunds declined by the network, a decline code provided by the network which indicates the reason the refund failed.
        attr_reader :network_decline_code

        def self.inner_class_types
          @inner_class_types = {}
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end

      class Pix < ::Stripe::StripeObject
        def self.inner_class_types
          @inner_class_types = {}
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end

      class Revolut < ::Stripe::StripeObject
        def self.inner_class_types
          @inner_class_types = {}
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end

      class Sofort < ::Stripe::StripeObject
        def self.inner_class_types
          @inner_class_types = {}
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end

      class Swish < ::Stripe::StripeObject
        # For refunds declined by the network, a decline code provided by the network which indicates the reason the refund failed.
        attr_reader :network_decline_code
        # The reference assigned to the refund.
        attr_reader :reference
        # Status of the reference on the refund. This can be `pending`, `available` or `unavailable`.
        attr_reader :reference_status

        def self.inner_class_types
          @inner_class_types = {}
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end

      class ThBankTransfer < ::Stripe::StripeObject
        # The reference assigned to the refund.
        attr_reader :reference
        # Status of the reference on the refund. This can be `pending`, `available` or `unavailable`.
        attr_reader :reference_status

        def self.inner_class_types
          @inner_class_types = {}
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end

      class Twint < ::Stripe::StripeObject
        def self.inner_class_types
          @inner_class_types = {}
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end

      class UsBankTransfer < ::Stripe::StripeObject
        # The reference assigned to the refund.
        attr_reader :reference
        # Status of the reference on the refund. This can be `pending`, `available` or `unavailable`.
        attr_reader :reference_status

        def self.inner_class_types
          @inner_class_types = {}
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end

      class WechatPay < ::Stripe::StripeObject
        def self.inner_class_types
          @inner_class_types = {}
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end

      class Zip < ::Stripe::StripeObject
        def self.inner_class_types
          @inner_class_types = {}
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end
      # Attribute for field affirm
      attr_reader :affirm
      # Attribute for field afterpay_clearpay
      attr_reader :afterpay_clearpay
      # Attribute for field alipay
      attr_reader :alipay
      # Attribute for field alma
      attr_reader :alma
      # Attribute for field amazon_pay
      attr_reader :amazon_pay
      # Attribute for field au_bank_transfer
      attr_reader :au_bank_transfer
      # Attribute for field blik
      attr_reader :blik
      # Attribute for field br_bank_transfer
      attr_reader :br_bank_transfer
      # Attribute for field card
      attr_reader :card
      # Attribute for field cashapp
      attr_reader :cashapp
      # Attribute for field crypto
      attr_reader :crypto
      # Attribute for field customer_cash_balance
      attr_reader :customer_cash_balance
      # Attribute for field eps
      attr_reader :eps
      # Attribute for field eu_bank_transfer
      attr_reader :eu_bank_transfer
      # Attribute for field gb_bank_transfer
      attr_reader :gb_bank_transfer
      # Attribute for field giropay
      attr_reader :giropay
      # Attribute for field grabpay
      attr_reader :grabpay
      # Attribute for field jp_bank_transfer
      attr_reader :jp_bank_transfer
      # Attribute for field klarna
      attr_reader :klarna
      # Attribute for field mb_way
      attr_reader :mb_way
      # Attribute for field multibanco
      attr_reader :multibanco
      # Attribute for field mx_bank_transfer
      attr_reader :mx_bank_transfer
      # Attribute for field nz_bank_transfer
      attr_reader :nz_bank_transfer
      # Attribute for field p24
      attr_reader :p24
      # Attribute for field paynow
      attr_reader :paynow
      # Attribute for field paypal
      attr_reader :paypal
      # Attribute for field pix
      attr_reader :pix
      # Attribute for field revolut
      attr_reader :revolut
      # Attribute for field sofort
      attr_reader :sofort
      # Attribute for field swish
      attr_reader :swish
      # Attribute for field th_bank_transfer
      attr_reader :th_bank_transfer
      # Attribute for field twint
      attr_reader :twint
      # The type of transaction-specific details of the payment method used in the refund (e.g., `card`). An additional hash is included on `destination_details` with a name matching this value. It contains information specific to the refund transaction.
      attr_reader :type
      # Attribute for field us_bank_transfer
      attr_reader :us_bank_transfer
      # Attribute for field wechat_pay
      attr_reader :wechat_pay
      # Attribute for field zip
      attr_reader :zip

      def self.inner_class_types
        @inner_class_types = {
          affirm: Affirm,
          afterpay_clearpay: AfterpayClearpay,
          alipay: Alipay,
          alma: Alma,
          amazon_pay: AmazonPay,
          au_bank_transfer: AuBankTransfer,
          blik: Blik,
          br_bank_transfer: BrBankTransfer,
          card: Card,
          cashapp: Cashapp,
          crypto: Crypto,
          customer_cash_balance: CustomerCashBalance,
          eps: Eps,
          eu_bank_transfer: EuBankTransfer,
          gb_bank_transfer: GbBankTransfer,
          giropay: Giropay,
          grabpay: Grabpay,
          jp_bank_transfer: JpBankTransfer,
          klarna: Klarna,
          mb_way: MbWay,
          multibanco: Multibanco,
          mx_bank_transfer: MxBankTransfer,
          nz_bank_transfer: NzBankTransfer,
          p24: P24,
          paynow: Paynow,
          paypal: Paypal,
          pix: Pix,
          revolut: Revolut,
          sofort: Sofort,
          swish: Swish,
          th_bank_transfer: ThBankTransfer,
          twint: Twint,
          us_bank_transfer: UsBankTransfer,
          wechat_pay: WechatPay,
          zip: Zip,
        }
      end

      def self.field_remappings
        @field_remappings = {}
      end
    end

    class NextAction < ::Stripe::StripeObject
      class DisplayDetails < ::Stripe::StripeObject
        class EmailSent < ::Stripe::StripeObject
          # The timestamp when the email was sent.
          attr_reader :email_sent_at
          # The recipient's email address.
          attr_reader :email_sent_to

          def self.inner_class_types
            @inner_class_types = {}
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end
        # Attribute for field email_sent
        attr_reader :email_sent
        # The expiry timestamp.
        attr_reader :expires_at

        def self.inner_class_types
          @inner_class_types = { email_sent: EmailSent }
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end
      # Attribute for field display_details
      attr_reader :display_details
      # Type of the next action to perform.
      attr_reader :type

      def self.inner_class_types
        @inner_class_types = { display_details: DisplayDetails }
      end

      def self.field_remappings
        @field_remappings = {}
      end
    end

    class PresentmentDetails < ::Stripe::StripeObject
      # Amount intended to be collected by this payment, denominated in `presentment_currency`.
      attr_reader :presentment_amount
      # Currency presented to the customer during payment.
      attr_reader :presentment_currency

      def self.inner_class_types
        @inner_class_types = {}
      end

      def self.field_remappings
        @field_remappings = {}
      end
    end
    # Amount, in cents (or local equivalent).
    attr_reader :amount
    # Balance transaction that describes the impact on your account balance.
    attr_reader :balance_transaction
    # ID of the charge that's refunded.
    attr_reader :charge
    # Time at which the object was created. Measured in seconds since the Unix epoch.
    attr_reader :created
    # Three-letter [ISO currency code](https://www.iso.org/iso-4217-currency-codes.html), in lowercase. Must be a [supported currency](https://stripe.com/docs/currencies).
    attr_reader :currency
    # An arbitrary string attached to the object. You can use this for displaying to users (available on non-card refunds only).
    attr_reader :description
    # Attribute for field destination_details
    attr_reader :destination_details
    # After the refund fails, this balance transaction describes the adjustment made on your account balance that reverses the initial balance transaction.
    attr_reader :failure_balance_transaction
    # Provides the reason for the refund failure. Possible values are: `lost_or_stolen_card`, `expired_or_canceled_card`, `charge_for_pending_refund_disputed`, `insufficient_funds`, `declined`, `merchant_request`, or `unknown`.
    attr_reader :failure_reason
    # Unique identifier for the object.
    attr_reader :id
    # For payment methods without native refund support (for example, Konbini, PromptPay), provide an email address for the customer to receive refund instructions.
    attr_reader :instructions_email
    # Set of [key-value pairs](https://stripe.com/docs/api/metadata) that you can attach to an object. This can be useful for storing additional information about the object in a structured format.
    attr_reader :metadata
    # Attribute for field next_action
    attr_reader :next_action
    # String representing the object's type. Objects of the same type share the same value.
    attr_reader :object
    # ID of the PaymentIntent that's refunded.
    attr_reader :payment_intent
    # Provides the reason for why the refund is pending. Possible values are: `processing`, `insufficient_funds`, or `charge_pending`.
    attr_reader :pending_reason
    # Attribute for field presentment_details
    attr_reader :presentment_details
    # Reason for the refund, which is either user-provided (`duplicate`, `fraudulent`, or `requested_by_customer`) or generated by Stripe internally (`expired_uncaptured_charge`).
    attr_reader :reason
    # This is the transaction number that appears on email receipts sent for this refund.
    attr_reader :receipt_number
    # The transfer reversal that's associated with the refund. Only present if the charge came from another Stripe account.
    attr_reader :source_transfer_reversal
    # Status of the refund. This can be `pending`, `requires_action`, `succeeded`, `failed`, or `canceled`. Learn more about [failed refunds](https://stripe.com/docs/refunds#failed-refunds).
    attr_reader :status
    # This refers to the transfer reversal object if the accompanying transfer reverses. This is only applicable if the charge was created using the destination parameter.
    attr_reader :transfer_reversal

    # Cancels a refund with a status of requires_action.
    #
    # You can't cancel refunds in other states. Only refunds for payment methods that require customer action can enter the requires_action state.
    def cancel(params = {}, opts = {})
      request_stripe_object(
        method: :post,
        path: format("/v1/refunds/%<refund>s/cancel", { refund: CGI.escape(self["id"]) }),
        params: params,
        opts: opts
      )
    end

    # Cancels a refund with a status of requires_action.
    #
    # You can't cancel refunds in other states. Only refunds for payment methods that require customer action can enter the requires_action state.
    def self.cancel(refund, params = {}, opts = {})
      request_stripe_object(
        method: :post,
        path: format("/v1/refunds/%<refund>s/cancel", { refund: CGI.escape(refund) }),
        params: params,
        opts: opts
      )
    end

    # When you create a new refund, you must specify a Charge or a PaymentIntent object on which to create it.
    #
    # Creating a new refund will refund a charge that has previously been created but not yet refunded.
    # Funds will be refunded to the credit or debit card that was originally charged.
    #
    # You can optionally refund only part of a charge.
    # You can do so multiple times, until the entire charge has been refunded.
    #
    # Once entirely refunded, a charge can't be refunded again.
    # This method will raise an error when called on an already-refunded charge,
    # or when trying to refund more money than is left on a charge.
    def self.create(params = {}, opts = {})
      request_stripe_object(method: :post, path: "/v1/refunds", params: params, opts: opts)
    end

    # Returns a list of all refunds you created. We return the refunds in sorted order, with the most recent refunds appearing first. The 10 most recent refunds are always available by default on the Charge object.
    def self.list(params = {}, opts = {})
      request_stripe_object(method: :get, path: "/v1/refunds", params: params, opts: opts)
    end

    # Updates the refund that you specify by setting the values of the passed parameters. Any parameters that you don't provide remain unchanged.
    #
    # This request only accepts metadata as an argument.
    def self.update(refund, params = {}, opts = {})
      request_stripe_object(
        method: :post,
        path: format("/v1/refunds/%<refund>s", { refund: CGI.escape(refund) }),
        params: params,
        opts: opts
      )
    end

    def test_helpers
      TestHelpers.new(self)
    end

    class TestHelpers < APIResourceTestHelpers
      RESOURCE_CLASS = Refund
      def self.resource_class
        "Refund"
      end

      # Expire a refund with a status of requires_action.
      def self.expire(refund, params = {}, opts = {})
        request_stripe_object(
          method: :post,
          path: format("/v1/test_helpers/refunds/%<refund>s/expire", { refund: CGI.escape(refund) }),
          params: params,
          opts: opts
        )
      end

      # Expire a refund with a status of requires_action.
      def expire(params = {}, opts = {})
        @resource.request_stripe_object(
          method: :post,
          path: format("/v1/test_helpers/refunds/%<refund>s/expire", { refund: CGI.escape(@resource["id"]) }),
          params: params,
          opts: opts
        )
      end
    end

    def self.inner_class_types
      @inner_class_types = {
        destination_details: DestinationDetails,
        next_action: NextAction,
        presentment_details: PresentmentDetails,
      }
    end

    def self.field_remappings
      @field_remappings = {}
    end
  end
end
