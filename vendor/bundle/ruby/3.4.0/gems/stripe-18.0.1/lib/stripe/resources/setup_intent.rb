# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  # A SetupIntent guides you through the process of setting up and saving a customer's payment credentials for future payments.
  # For example, you can use a SetupIntent to set up and save your customer's card without immediately collecting a payment.
  # Later, you can use [PaymentIntents](https://stripe.com/docs/api#payment_intents) to drive the payment flow.
  #
  # Create a SetupIntent when you're ready to collect your customer's payment credentials.
  # Don't maintain long-lived, unconfirmed SetupIntents because they might not be valid.
  # The SetupIntent transitions through multiple [statuses](https://docs.stripe.com/payments/intents#intent-statuses) as it guides
  # you through the setup process.
  #
  # Successful SetupIntents result in payment credentials that are optimized for future payments.
  # For example, cardholders in [certain regions](https://stripe.com/guides/strong-customer-authentication) might need to be run through
  # [Strong Customer Authentication](https://docs.stripe.com/strong-customer-authentication) during payment method collection
  # to streamline later [off-session payments](https://docs.stripe.com/payments/setup-intents).
  # If you use the SetupIntent with a [Customer](https://stripe.com/docs/api#setup_intent_object-customer),
  # it automatically attaches the resulting payment method to that Customer after successful setup.
  # We recommend using SetupIntents or [setup_future_usage](https://stripe.com/docs/api#payment_intent_object-setup_future_usage) on
  # PaymentIntents to save payment methods to prevent saving invalid or unoptimized payment methods.
  #
  # By using SetupIntents, you can reduce friction for your customers, even as regulations change over time.
  #
  # Related guide: [Setup Intents API](https://docs.stripe.com/payments/setup-intents)
  class SetupIntent < APIResource
    extend Stripe::APIOperations::Create
    extend Stripe::APIOperations::List
    include Stripe::APIOperations::Save

    OBJECT_NAME = "setup_intent"
    def self.object_name
      "setup_intent"
    end

    class AutomaticPaymentMethods < ::Stripe::StripeObject
      # Controls whether this SetupIntent will accept redirect-based payment methods.
      #
      # Redirect-based payment methods may require your customer to be redirected to a payment method's app or site for authentication or additional steps. To [confirm](https://stripe.com/docs/api/setup_intents/confirm) this SetupIntent, you may be required to provide a `return_url` to redirect customers back to your site after they authenticate or complete the setup.
      attr_reader :allow_redirects
      # Automatically calculates compatible payment methods
      attr_reader :enabled

      def self.inner_class_types
        @inner_class_types = {}
      end

      def self.field_remappings
        @field_remappings = {}
      end
    end

    class LastSetupError < ::Stripe::StripeObject
      # For card errors resulting from a card issuer decline, a short string indicating [how to proceed with an error](https://stripe.com/docs/declines#retrying-issuer-declines) if they provide one.
      attr_reader :advice_code
      # For card errors, the ID of the failed charge.
      attr_reader :charge
      # For some errors that could be handled programmatically, a short string indicating the [error code](https://stripe.com/docs/error-codes) reported.
      attr_reader :code
      # For card errors resulting from a card issuer decline, a short string indicating the [card issuer's reason for the decline](https://stripe.com/docs/declines#issuer-declines) if they provide one.
      attr_reader :decline_code
      # A URL to more information about the [error code](https://stripe.com/docs/error-codes) reported.
      attr_reader :doc_url
      # A human-readable message providing more details about the error. For card errors, these messages can be shown to your users.
      attr_reader :message
      # For card errors resulting from a card issuer decline, a 2 digit code which indicates the advice given to merchant by the card network on how to proceed with an error.
      attr_reader :network_advice_code
      # For payments declined by the network, an alphanumeric code which indicates the reason the payment failed.
      attr_reader :network_decline_code
      # If the error is parameter-specific, the parameter related to the error. For example, you can use this to display a message near the correct form field.
      attr_reader :param
      # A PaymentIntent guides you through the process of collecting a payment from your customer.
      # We recommend that you create exactly one PaymentIntent for each order or
      # customer session in your system. You can reference the PaymentIntent later to
      # see the history of payment attempts for a particular session.
      #
      # A PaymentIntent transitions through
      # [multiple statuses](https://stripe.com/docs/payments/intents#intent-statuses)
      # throughout its lifetime as it interfaces with Stripe.js to perform
      # authentication flows and ultimately creates at most one successful charge.
      #
      # Related guide: [Payment Intents API](https://stripe.com/docs/payments/payment-intents)
      attr_reader :payment_intent
      # PaymentMethod objects represent your customer's payment instruments.
      # You can use them with [PaymentIntents](https://stripe.com/docs/payments/payment-intents) to collect payments or save them to
      # Customer objects to store instrument details for future payments.
      #
      # Related guides: [Payment Methods](https://stripe.com/docs/payments/payment-methods) and [More Payment Scenarios](https://stripe.com/docs/payments/more-payment-scenarios).
      attr_reader :payment_method
      # If the error is specific to the type of payment method, the payment method type that had a problem. This field is only populated for invoice-related errors.
      attr_reader :payment_method_type
      # A URL to the request log entry in your dashboard.
      attr_reader :request_log_url
      # A SetupIntent guides you through the process of setting up and saving a customer's payment credentials for future payments.
      # For example, you can use a SetupIntent to set up and save your customer's card without immediately collecting a payment.
      # Later, you can use [PaymentIntents](https://stripe.com/docs/api#payment_intents) to drive the payment flow.
      #
      # Create a SetupIntent when you're ready to collect your customer's payment credentials.
      # Don't maintain long-lived, unconfirmed SetupIntents because they might not be valid.
      # The SetupIntent transitions through multiple [statuses](https://docs.stripe.com/payments/intents#intent-statuses) as it guides
      # you through the setup process.
      #
      # Successful SetupIntents result in payment credentials that are optimized for future payments.
      # For example, cardholders in [certain regions](https://stripe.com/guides/strong-customer-authentication) might need to be run through
      # [Strong Customer Authentication](https://docs.stripe.com/strong-customer-authentication) during payment method collection
      # to streamline later [off-session payments](https://docs.stripe.com/payments/setup-intents).
      # If you use the SetupIntent with a [Customer](https://stripe.com/docs/api#setup_intent_object-customer),
      # it automatically attaches the resulting payment method to that Customer after successful setup.
      # We recommend using SetupIntents or [setup_future_usage](https://stripe.com/docs/api#payment_intent_object-setup_future_usage) on
      # PaymentIntents to save payment methods to prevent saving invalid or unoptimized payment methods.
      #
      # By using SetupIntents, you can reduce friction for your customers, even as regulations change over time.
      #
      # Related guide: [Setup Intents API](https://docs.stripe.com/payments/setup-intents)
      attr_reader :setup_intent
      # Attribute for field source
      attr_reader :source
      # The type of error returned. One of `api_error`, `card_error`, `idempotency_error`, or `invalid_request_error`
      attr_reader :type

      def self.inner_class_types
        @inner_class_types = {}
      end

      def self.field_remappings
        @field_remappings = {}
      end
    end

    class NextAction < ::Stripe::StripeObject
      class CashappHandleRedirectOrDisplayQrCode < ::Stripe::StripeObject
        class QrCode < ::Stripe::StripeObject
          # The date (unix timestamp) when the QR code expires.
          attr_reader :expires_at
          # The image_url_png string used to render QR code
          attr_reader :image_url_png
          # The image_url_svg string used to render QR code
          attr_reader :image_url_svg

          def self.inner_class_types
            @inner_class_types = {}
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end
        # The URL to the hosted Cash App Pay instructions page, which allows customers to view the QR code, and supports QR code refreshing on expiration.
        attr_reader :hosted_instructions_url
        # The url for mobile redirect based auth
        attr_reader :mobile_auth_url
        # Attribute for field qr_code
        attr_reader :qr_code

        def self.inner_class_types
          @inner_class_types = { qr_code: QrCode }
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end

      class RedirectToUrl < ::Stripe::StripeObject
        # If the customer does not exit their browser while authenticating, they will be redirected to this specified URL after completion.
        attr_reader :return_url
        # The URL you must redirect your customer to in order to authenticate.
        attr_reader :url

        def self.inner_class_types
          @inner_class_types = {}
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end

      class VerifyWithMicrodeposits < ::Stripe::StripeObject
        # The timestamp when the microdeposits are expected to land.
        attr_reader :arrival_date
        # The URL for the hosted verification page, which allows customers to verify their bank account.
        attr_reader :hosted_verification_url
        # The type of the microdeposit sent to the customer. Used to distinguish between different verification methods.
        attr_reader :microdeposit_type

        def self.inner_class_types
          @inner_class_types = {}
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end
      # Attribute for field cashapp_handle_redirect_or_display_qr_code
      attr_reader :cashapp_handle_redirect_or_display_qr_code
      # Attribute for field redirect_to_url
      attr_reader :redirect_to_url
      # Type of the next action to perform. Refer to the other child attributes under `next_action` for available values. Examples include: `redirect_to_url`, `use_stripe_sdk`, `alipay_handle_redirect`, `oxxo_display_details`, or `verify_with_microdeposits`.
      attr_reader :type
      # When confirming a SetupIntent with Stripe.js, Stripe.js depends on the contents of this dictionary to invoke authentication flows. The shape of the contents is subject to change and is only intended to be used by Stripe.js.
      attr_reader :use_stripe_sdk
      # Attribute for field verify_with_microdeposits
      attr_reader :verify_with_microdeposits

      def self.inner_class_types
        @inner_class_types = {
          cashapp_handle_redirect_or_display_qr_code: CashappHandleRedirectOrDisplayQrCode,
          redirect_to_url: RedirectToUrl,
          verify_with_microdeposits: VerifyWithMicrodeposits,
        }
      end

      def self.field_remappings
        @field_remappings = {}
      end
    end

    class PaymentMethodConfigurationDetails < ::Stripe::StripeObject
      # ID of the payment method configuration used.
      attr_reader :id
      # ID of the parent payment method configuration used.
      attr_reader :parent

      def self.inner_class_types
        @inner_class_types = {}
      end

      def self.field_remappings
        @field_remappings = {}
      end
    end

    class PaymentMethodOptions < ::Stripe::StripeObject
      class AcssDebit < ::Stripe::StripeObject
        class MandateOptions < ::Stripe::StripeObject
          # A URL for custom mandate text
          attr_reader :custom_mandate_url
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
        # Currency supported by the bank account
        attr_reader :currency
        # Attribute for field mandate_options
        attr_reader :mandate_options
        # Bank account verification method.
        attr_reader :verification_method

        def self.inner_class_types
          @inner_class_types = { mandate_options: MandateOptions }
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

      class BacsDebit < ::Stripe::StripeObject
        class MandateOptions < ::Stripe::StripeObject
          # Prefix used to generate the Mandate reference. Must be at most 12 characters long. Must consist of only uppercase letters, numbers, spaces, or the following special characters: '/', '_', '-', '&', '.'. Cannot begin with 'DDIC' or 'STRIPE'.
          attr_reader :reference_prefix

          def self.inner_class_types
            @inner_class_types = {}
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end
        # Attribute for field mandate_options
        attr_reader :mandate_options

        def self.inner_class_types
          @inner_class_types = { mandate_options: MandateOptions }
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end

      class Card < ::Stripe::StripeObject
        class MandateOptions < ::Stripe::StripeObject
          # Amount to be charged for future payments.
          attr_reader :amount
          # One of `fixed` or `maximum`. If `fixed`, the `amount` param refers to the exact amount to be charged in future payments. If `maximum`, the amount charged can be up to the value passed for the `amount` param.
          attr_reader :amount_type
          # Three-letter [ISO currency code](https://www.iso.org/iso-4217-currency-codes.html), in lowercase. Must be a [supported currency](https://stripe.com/docs/currencies).
          attr_reader :currency
          # A description of the mandate or subscription that is meant to be displayed to the customer.
          attr_reader :description
          # End date of the mandate or subscription. If not provided, the mandate will be active until canceled. If provided, end date should be after start date.
          attr_reader :end_date
          # Specifies payment frequency. One of `day`, `week`, `month`, `year`, or `sporadic`.
          attr_reader :interval
          # The number of intervals between payments. For example, `interval=month` and `interval_count=3` indicates one payment every three months. Maximum of one year interval allowed (1 year, 12 months, or 52 weeks). This parameter is optional when `interval=sporadic`.
          attr_reader :interval_count
          # Unique identifier for the mandate or subscription.
          attr_reader :reference
          # Start date of the mandate or subscription. Start date should not be lesser than yesterday.
          attr_reader :start_date
          # Specifies the type of mandates supported. Possible values are `india`.
          attr_reader :supported_types

          def self.inner_class_types
            @inner_class_types = {}
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end
        # Configuration options for setting up an eMandate for cards issued in India.
        attr_reader :mandate_options
        # Selected network to process this SetupIntent on. Depends on the available networks of the card attached to the setup intent. Can be only set confirm-time.
        attr_reader :network
        # We strongly recommend that you rely on our SCA Engine to automatically prompt your customers for authentication based on risk level and [other requirements](https://stripe.com/docs/strong-customer-authentication). However, if you wish to request 3D Secure based on logic from your own fraud engine, provide this option. If not provided, this value defaults to `automatic`. Read our guide on [manually requesting 3D Secure](https://stripe.com/docs/payments/3d-secure/authentication-flow#manual-three-ds) for more information on how this configuration interacts with Radar and our SCA Engine.
        attr_reader :request_three_d_secure

        def self.inner_class_types
          @inner_class_types = { mandate_options: MandateOptions }
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end

      class CardPresent < ::Stripe::StripeObject
        def self.inner_class_types
          @inner_class_types = {}
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end

      class Klarna < ::Stripe::StripeObject
        # The currency of the setup intent. Three letter ISO currency code.
        attr_reader :currency
        # Preferred locale of the Klarna checkout page that the customer is redirected to.
        attr_reader :preferred_locale

        def self.inner_class_types
          @inner_class_types = {}
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end

      class Link < ::Stripe::StripeObject
        # [Deprecated] This is a legacy parameter that no longer has any function.
        attr_reader :persistent_token

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

        def self.inner_class_types
          @inner_class_types = {}
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end

      class SepaDebit < ::Stripe::StripeObject
        class MandateOptions < ::Stripe::StripeObject
          # Prefix used to generate the Mandate reference. Must be at most 12 characters long. Must consist of only uppercase letters, numbers, spaces, or the following special characters: '/', '_', '-', '&', '.'. Cannot begin with 'STRIPE'.
          attr_reader :reference_prefix

          def self.inner_class_types
            @inner_class_types = {}
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end
        # Attribute for field mandate_options
        attr_reader :mandate_options

        def self.inner_class_types
          @inner_class_types = { mandate_options: MandateOptions }
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end

      class UsBankAccount < ::Stripe::StripeObject
        class FinancialConnections < ::Stripe::StripeObject
          class Filters < ::Stripe::StripeObject
            # The account subcategories to use to filter for possible accounts to link. Valid subcategories are `checking` and `savings`.
            attr_reader :account_subcategories

            def self.inner_class_types
              @inner_class_types = {}
            end

            def self.field_remappings
              @field_remappings = {}
            end
          end
          # Attribute for field filters
          attr_reader :filters
          # The list of permissions to request. The `payment_method` permission must be included.
          attr_reader :permissions
          # Data features requested to be retrieved upon account creation.
          attr_reader :prefetch
          # For webview integrations only. Upon completing OAuth login in the native browser, the user will be redirected to this URL to return to your app.
          attr_reader :return_url

          def self.inner_class_types
            @inner_class_types = { filters: Filters }
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end

        class MandateOptions < ::Stripe::StripeObject
          # Mandate collection method
          attr_reader :collection_method

          def self.inner_class_types
            @inner_class_types = {}
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end
        # Attribute for field financial_connections
        attr_reader :financial_connections
        # Attribute for field mandate_options
        attr_reader :mandate_options
        # Bank account verification method.
        attr_reader :verification_method

        def self.inner_class_types
          @inner_class_types = {
            financial_connections: FinancialConnections,
            mandate_options: MandateOptions,
          }
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end
      # Attribute for field acss_debit
      attr_reader :acss_debit
      # Attribute for field amazon_pay
      attr_reader :amazon_pay
      # Attribute for field bacs_debit
      attr_reader :bacs_debit
      # Attribute for field card
      attr_reader :card
      # Attribute for field card_present
      attr_reader :card_present
      # Attribute for field klarna
      attr_reader :klarna
      # Attribute for field link
      attr_reader :link
      # Attribute for field paypal
      attr_reader :paypal
      # Attribute for field sepa_debit
      attr_reader :sepa_debit
      # Attribute for field us_bank_account
      attr_reader :us_bank_account

      def self.inner_class_types
        @inner_class_types = {
          acss_debit: AcssDebit,
          amazon_pay: AmazonPay,
          bacs_debit: BacsDebit,
          card: Card,
          card_present: CardPresent,
          klarna: Klarna,
          link: Link,
          paypal: Paypal,
          sepa_debit: SepaDebit,
          us_bank_account: UsBankAccount,
        }
      end

      def self.field_remappings
        @field_remappings = {}
      end
    end
    # ID of the Connect application that created the SetupIntent.
    attr_reader :application
    # If present, the SetupIntent's payment method will be attached to the in-context Stripe Account.
    #
    # It can only be used for this Stripe Account’s own money movement flows like InboundTransfer and OutboundTransfers. It cannot be set to true when setting up a PaymentMethod for a Customer, and defaults to false when attaching a PaymentMethod to a Customer.
    attr_reader :attach_to_self
    # Settings for dynamic payment methods compatible with this Setup Intent
    attr_reader :automatic_payment_methods
    # Reason for cancellation of this SetupIntent, one of `abandoned`, `requested_by_customer`, or `duplicate`.
    attr_reader :cancellation_reason
    # The client secret of this SetupIntent. Used for client-side retrieval using a publishable key.
    #
    # The client secret can be used to complete payment setup from your frontend. It should not be stored, logged, or exposed to anyone other than the customer. Make sure that you have TLS enabled on any page that includes the client secret.
    attr_reader :client_secret
    # Time at which the object was created. Measured in seconds since the Unix epoch.
    attr_reader :created
    # ID of the Customer this SetupIntent belongs to, if one exists.
    #
    # If present, the SetupIntent's payment method will be attached to the Customer on successful setup. Payment methods attached to other Customers cannot be used with this SetupIntent.
    attr_reader :customer
    # An arbitrary string attached to the object. Often useful for displaying to users.
    attr_reader :description
    # Payment method types that are excluded from this SetupIntent.
    attr_reader :excluded_payment_method_types
    # Indicates the directions of money movement for which this payment method is intended to be used.
    #
    # Include `inbound` if you intend to use the payment method as the origin to pull funds from. Include `outbound` if you intend to use the payment method as the destination to send funds to. You can include both if you intend to use the payment method for both purposes.
    attr_reader :flow_directions
    # Unique identifier for the object.
    attr_reader :id
    # The error encountered in the previous SetupIntent confirmation.
    attr_reader :last_setup_error
    # The most recent SetupAttempt for this SetupIntent.
    attr_reader :latest_attempt
    # Has the value `true` if the object exists in live mode or the value `false` if the object exists in test mode.
    attr_reader :livemode
    # ID of the multi use Mandate generated by the SetupIntent.
    attr_reader :mandate
    # Set of [key-value pairs](https://stripe.com/docs/api/metadata) that you can attach to an object. This can be useful for storing additional information about the object in a structured format.
    attr_reader :metadata
    # If present, this property tells you what actions you need to take in order for your customer to continue payment setup.
    attr_reader :next_action
    # String representing the object's type. Objects of the same type share the same value.
    attr_reader :object
    # The account (if any) for which the setup is intended.
    attr_reader :on_behalf_of
    # ID of the payment method used with this SetupIntent. If the payment method is `card_present` and isn't a digital wallet, then the [generated_card](https://docs.stripe.com/api/setup_attempts/object#setup_attempt_object-payment_method_details-card_present-generated_card) associated with the `latest_attempt` is attached to the Customer instead.
    attr_reader :payment_method
    # Information about the [payment method configuration](https://stripe.com/docs/api/payment_method_configurations) used for this Setup Intent.
    attr_reader :payment_method_configuration_details
    # Payment method-specific configuration for this SetupIntent.
    attr_reader :payment_method_options
    # The list of payment method types (e.g. card) that this SetupIntent is allowed to set up. A list of valid payment method types can be found [here](https://docs.stripe.com/api/payment_methods/object#payment_method_object-type).
    attr_reader :payment_method_types
    # ID of the single_use Mandate generated by the SetupIntent.
    attr_reader :single_use_mandate
    # [Status](https://stripe.com/docs/payments/intents#intent-statuses) of this SetupIntent, one of `requires_payment_method`, `requires_confirmation`, `requires_action`, `processing`, `canceled`, or `succeeded`.
    attr_reader :status
    # Indicates how the payment method is intended to be used in the future.
    #
    # Use `on_session` if you intend to only reuse the payment method when the customer is in your checkout flow. Use `off_session` if your customer may or may not be in your checkout flow. If not provided, this value defaults to `off_session`.
    attr_reader :usage

    # You can cancel a SetupIntent object when it's in one of these statuses: requires_payment_method, requires_confirmation, or requires_action.
    #
    # After you cancel it, setup is abandoned and any operations on the SetupIntent fail with an error. You can't cancel the SetupIntent for a Checkout Session. [Expire the Checkout Session](https://docs.stripe.com/docs/api/checkout/sessions/expire) instead.
    def cancel(params = {}, opts = {})
      request_stripe_object(
        method: :post,
        path: format("/v1/setup_intents/%<intent>s/cancel", { intent: CGI.escape(self["id"]) }),
        params: params,
        opts: opts
      )
    end

    # You can cancel a SetupIntent object when it's in one of these statuses: requires_payment_method, requires_confirmation, or requires_action.
    #
    # After you cancel it, setup is abandoned and any operations on the SetupIntent fail with an error. You can't cancel the SetupIntent for a Checkout Session. [Expire the Checkout Session](https://docs.stripe.com/docs/api/checkout/sessions/expire) instead.
    def self.cancel(intent, params = {}, opts = {})
      request_stripe_object(
        method: :post,
        path: format("/v1/setup_intents/%<intent>s/cancel", { intent: CGI.escape(intent) }),
        params: params,
        opts: opts
      )
    end

    # Confirm that your customer intends to set up the current or
    # provided payment method. For example, you would confirm a SetupIntent
    # when a customer hits the “Save” button on a payment method management
    # page on your website.
    #
    # If the selected payment method does not require any additional
    # steps from the customer, the SetupIntent will transition to the
    # succeeded status.
    #
    # Otherwise, it will transition to the requires_action status and
    # suggest additional actions via next_action. If setup fails,
    # the SetupIntent will transition to the
    # requires_payment_method status or the canceled status if the
    # confirmation limit is reached.
    def confirm(params = {}, opts = {})
      request_stripe_object(
        method: :post,
        path: format("/v1/setup_intents/%<intent>s/confirm", { intent: CGI.escape(self["id"]) }),
        params: params,
        opts: opts
      )
    end

    # Confirm that your customer intends to set up the current or
    # provided payment method. For example, you would confirm a SetupIntent
    # when a customer hits the “Save” button on a payment method management
    # page on your website.
    #
    # If the selected payment method does not require any additional
    # steps from the customer, the SetupIntent will transition to the
    # succeeded status.
    #
    # Otherwise, it will transition to the requires_action status and
    # suggest additional actions via next_action. If setup fails,
    # the SetupIntent will transition to the
    # requires_payment_method status or the canceled status if the
    # confirmation limit is reached.
    def self.confirm(intent, params = {}, opts = {})
      request_stripe_object(
        method: :post,
        path: format("/v1/setup_intents/%<intent>s/confirm", { intent: CGI.escape(intent) }),
        params: params,
        opts: opts
      )
    end

    # Creates a SetupIntent object.
    #
    # After you create the SetupIntent, attach a payment method and [confirm](https://docs.stripe.com/docs/api/setup_intents/confirm)
    # it to collect any required permissions to charge the payment method later.
    def self.create(params = {}, opts = {})
      request_stripe_object(method: :post, path: "/v1/setup_intents", params: params, opts: opts)
    end

    # Returns a list of SetupIntents.
    def self.list(params = {}, opts = {})
      request_stripe_object(method: :get, path: "/v1/setup_intents", params: params, opts: opts)
    end

    # Updates a SetupIntent object.
    def self.update(intent, params = {}, opts = {})
      request_stripe_object(
        method: :post,
        path: format("/v1/setup_intents/%<intent>s", { intent: CGI.escape(intent) }),
        params: params,
        opts: opts
      )
    end

    # Verifies microdeposits on a SetupIntent object.
    def verify_microdeposits(params = {}, opts = {})
      request_stripe_object(
        method: :post,
        path: format("/v1/setup_intents/%<intent>s/verify_microdeposits", { intent: CGI.escape(self["id"]) }),
        params: params,
        opts: opts
      )
    end

    # Verifies microdeposits on a SetupIntent object.
    def self.verify_microdeposits(intent, params = {}, opts = {})
      request_stripe_object(
        method: :post,
        path: format("/v1/setup_intents/%<intent>s/verify_microdeposits", { intent: CGI.escape(intent) }),
        params: params,
        opts: opts
      )
    end

    def self.inner_class_types
      @inner_class_types = {
        automatic_payment_methods: AutomaticPaymentMethods,
        last_setup_error: LastSetupError,
        next_action: NextAction,
        payment_method_configuration_details: PaymentMethodConfigurationDetails,
        payment_method_options: PaymentMethodOptions,
      }
    end

    def self.field_remappings
      @field_remappings = {}
    end
  end
end
