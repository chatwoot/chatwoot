# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  # A payment link is a shareable URL that will take your customers to a hosted payment page. A payment link can be shared and used multiple times.
  #
  # When a customer opens a payment link it will open a new [checkout session](https://stripe.com/docs/api/checkout/sessions) to render the payment page. You can use [checkout session events](https://stripe.com/docs/api/events/types#event_types-checkout.session.completed) to track payments through payment links.
  #
  # Related guide: [Payment Links API](https://stripe.com/docs/payment-links)
  class PaymentLink < APIResource
    extend Stripe::APIOperations::Create
    extend Stripe::APIOperations::List
    include Stripe::APIOperations::Save

    OBJECT_NAME = "payment_link"
    def self.object_name
      "payment_link"
    end

    class AfterCompletion < ::Stripe::StripeObject
      class HostedConfirmation < ::Stripe::StripeObject
        # The custom message that is displayed to the customer after the purchase is complete.
        attr_reader :custom_message

        def self.inner_class_types
          @inner_class_types = {}
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end

      class Redirect < ::Stripe::StripeObject
        # The URL the customer will be redirected to after the purchase is complete.
        attr_reader :url

        def self.inner_class_types
          @inner_class_types = {}
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end
      # Attribute for field hosted_confirmation
      attr_reader :hosted_confirmation
      # Attribute for field redirect
      attr_reader :redirect
      # The specified behavior after the purchase is complete.
      attr_reader :type

      def self.inner_class_types
        @inner_class_types = { hosted_confirmation: HostedConfirmation, redirect: Redirect }
      end

      def self.field_remappings
        @field_remappings = {}
      end
    end

    class AutomaticTax < ::Stripe::StripeObject
      class Liability < ::Stripe::StripeObject
        # The connected account being referenced when `type` is `account`.
        attr_reader :account
        # Type of the account referenced.
        attr_reader :type

        def self.inner_class_types
          @inner_class_types = {}
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end
      # If `true`, tax will be calculated automatically using the customer's location.
      attr_reader :enabled
      # The account that's liable for tax. If set, the business address and tax registrations required to perform the tax calculation are loaded from this account. The tax transaction is returned in the report of the connected account.
      attr_reader :liability

      def self.inner_class_types
        @inner_class_types = { liability: Liability }
      end

      def self.field_remappings
        @field_remappings = {}
      end
    end

    class ConsentCollection < ::Stripe::StripeObject
      class PaymentMethodReuseAgreement < ::Stripe::StripeObject
        # Determines the position and visibility of the payment method reuse agreement in the UI. When set to `auto`, Stripe's defaults will be used.
        #
        # When set to `hidden`, the payment method reuse agreement text will always be hidden in the UI.
        attr_reader :position

        def self.inner_class_types
          @inner_class_types = {}
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end
      # Settings related to the payment method reuse text shown in the Checkout UI.
      attr_reader :payment_method_reuse_agreement
      # If set to `auto`, enables the collection of customer consent for promotional communications.
      attr_reader :promotions
      # If set to `required`, it requires cutomers to accept the terms of service before being able to pay. If set to `none`, customers won't be shown a checkbox to accept the terms of service.
      attr_reader :terms_of_service

      def self.inner_class_types
        @inner_class_types = { payment_method_reuse_agreement: PaymentMethodReuseAgreement }
      end

      def self.field_remappings
        @field_remappings = {}
      end
    end

    class CustomField < ::Stripe::StripeObject
      class Dropdown < ::Stripe::StripeObject
        class Option < ::Stripe::StripeObject
          # The label for the option, displayed to the customer. Up to 100 characters.
          attr_reader :label
          # The value for this option, not displayed to the customer, used by your integration to reconcile the option selected by the customer. Must be unique to this option, alphanumeric, and up to 100 characters.
          attr_reader :value

          def self.inner_class_types
            @inner_class_types = {}
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end
        # The value that will pre-fill on the payment page.
        attr_reader :default_value
        # The options available for the customer to select. Up to 200 options allowed.
        attr_reader :options

        def self.inner_class_types
          @inner_class_types = { options: Option }
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end

      class Label < ::Stripe::StripeObject
        # Custom text for the label, displayed to the customer. Up to 50 characters.
        attr_reader :custom
        # The type of the label.
        attr_reader :type

        def self.inner_class_types
          @inner_class_types = {}
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end

      class Numeric < ::Stripe::StripeObject
        # The value that will pre-fill the field on the payment page.
        attr_reader :default_value
        # The maximum character length constraint for the customer's input.
        attr_reader :maximum_length
        # The minimum character length requirement for the customer's input.
        attr_reader :minimum_length

        def self.inner_class_types
          @inner_class_types = {}
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end

      class Text < ::Stripe::StripeObject
        # The value that will pre-fill the field on the payment page.
        attr_reader :default_value
        # The maximum character length constraint for the customer's input.
        attr_reader :maximum_length
        # The minimum character length requirement for the customer's input.
        attr_reader :minimum_length

        def self.inner_class_types
          @inner_class_types = {}
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end
      # Attribute for field dropdown
      attr_reader :dropdown
      # String of your choice that your integration can use to reconcile this field. Must be unique to this field, alphanumeric, and up to 200 characters.
      attr_reader :key
      # Attribute for field label
      attr_reader :label
      # Attribute for field numeric
      attr_reader :numeric
      # Whether the customer is required to complete the field before completing the Checkout Session. Defaults to `false`.
      attr_reader :optional
      # Attribute for field text
      attr_reader :text
      # The type of the field.
      attr_reader :type

      def self.inner_class_types
        @inner_class_types = { dropdown: Dropdown, label: Label, numeric: Numeric, text: Text }
      end

      def self.field_remappings
        @field_remappings = {}
      end
    end

    class CustomText < ::Stripe::StripeObject
      class AfterSubmit < ::Stripe::StripeObject
        # Text may be up to 1200 characters in length.
        attr_reader :message

        def self.inner_class_types
          @inner_class_types = {}
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end

      class ShippingAddress < ::Stripe::StripeObject
        # Text may be up to 1200 characters in length.
        attr_reader :message

        def self.inner_class_types
          @inner_class_types = {}
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end

      class Submit < ::Stripe::StripeObject
        # Text may be up to 1200 characters in length.
        attr_reader :message

        def self.inner_class_types
          @inner_class_types = {}
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end

      class TermsOfServiceAcceptance < ::Stripe::StripeObject
        # Text may be up to 1200 characters in length.
        attr_reader :message

        def self.inner_class_types
          @inner_class_types = {}
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end
      # Custom text that should be displayed after the payment confirmation button.
      attr_reader :after_submit
      # Custom text that should be displayed alongside shipping address collection.
      attr_reader :shipping_address
      # Custom text that should be displayed alongside the payment confirmation button.
      attr_reader :submit
      # Custom text that should be displayed in place of the default terms of service agreement text.
      attr_reader :terms_of_service_acceptance

      def self.inner_class_types
        @inner_class_types = {
          after_submit: AfterSubmit,
          shipping_address: ShippingAddress,
          submit: Submit,
          terms_of_service_acceptance: TermsOfServiceAcceptance,
        }
      end

      def self.field_remappings
        @field_remappings = {}
      end
    end

    class InvoiceCreation < ::Stripe::StripeObject
      class InvoiceData < ::Stripe::StripeObject
        class CustomField < ::Stripe::StripeObject
          # The name of the custom field.
          attr_reader :name
          # The value of the custom field.
          attr_reader :value

          def self.inner_class_types
            @inner_class_types = {}
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end

        class Issuer < ::Stripe::StripeObject
          # The connected account being referenced when `type` is `account`.
          attr_reader :account
          # Type of the account referenced.
          attr_reader :type

          def self.inner_class_types
            @inner_class_types = {}
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end

        class RenderingOptions < ::Stripe::StripeObject
          # How line-item prices and amounts will be displayed with respect to tax on invoice PDFs.
          attr_reader :amount_tax_display
          # ID of the invoice rendering template to be used for the generated invoice.
          attr_reader :template

          def self.inner_class_types
            @inner_class_types = {}
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end
        # The account tax IDs associated with the invoice.
        attr_reader :account_tax_ids
        # A list of up to 4 custom fields to be displayed on the invoice.
        attr_reader :custom_fields
        # An arbitrary string attached to the object. Often useful for displaying to users.
        attr_reader :description
        # Footer to be displayed on the invoice.
        attr_reader :footer
        # The connected account that issues the invoice. The invoice is presented with the branding and support information of the specified account.
        attr_reader :issuer
        # Set of [key-value pairs](https://stripe.com/docs/api/metadata) that you can attach to an object. This can be useful for storing additional information about the object in a structured format.
        attr_reader :metadata
        # Options for invoice PDF rendering.
        attr_reader :rendering_options

        def self.inner_class_types
          @inner_class_types = {
            custom_fields: CustomField,
            issuer: Issuer,
            rendering_options: RenderingOptions,
          }
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end
      # Enable creating an invoice on successful payment.
      attr_reader :enabled
      # Configuration for the invoice. Default invoice values will be used if unspecified.
      attr_reader :invoice_data

      def self.inner_class_types
        @inner_class_types = { invoice_data: InvoiceData }
      end

      def self.field_remappings
        @field_remappings = {}
      end
    end

    class NameCollection < ::Stripe::StripeObject
      class Business < ::Stripe::StripeObject
        # Indicates whether business name collection is enabled for the payment link.
        attr_reader :enabled
        # Whether the customer is required to complete the field before checking out. Defaults to `false`.
        attr_reader :optional

        def self.inner_class_types
          @inner_class_types = {}
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end

      class Individual < ::Stripe::StripeObject
        # Indicates whether individual name collection is enabled for the payment link.
        attr_reader :enabled
        # Whether the customer is required to complete the field before checking out. Defaults to `false`.
        attr_reader :optional

        def self.inner_class_types
          @inner_class_types = {}
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end
      # Attribute for field business
      attr_reader :business
      # Attribute for field individual
      attr_reader :individual

      def self.inner_class_types
        @inner_class_types = { business: Business, individual: Individual }
      end

      def self.field_remappings
        @field_remappings = {}
      end
    end

    class OptionalItem < ::Stripe::StripeObject
      class AdjustableQuantity < ::Stripe::StripeObject
        # Set to true if the quantity can be adjusted to any non-negative integer.
        attr_reader :enabled
        # The maximum quantity of this item the customer can purchase. By default this value is 99.
        attr_reader :maximum
        # The minimum quantity of this item the customer must purchase, if they choose to purchase it. Because this item is optional, the customer will always be able to remove it from their order, even if the `minimum` configured here is greater than 0. By default this value is 0.
        attr_reader :minimum

        def self.inner_class_types
          @inner_class_types = {}
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end
      # Attribute for field adjustable_quantity
      attr_reader :adjustable_quantity
      # Attribute for field price
      attr_reader :price
      # Attribute for field quantity
      attr_reader :quantity

      def self.inner_class_types
        @inner_class_types = { adjustable_quantity: AdjustableQuantity }
      end

      def self.field_remappings
        @field_remappings = {}
      end
    end

    class PaymentIntentData < ::Stripe::StripeObject
      # Indicates when the funds will be captured from the customer's account.
      attr_reader :capture_method
      # An arbitrary string attached to the object. Often useful for displaying to users.
      attr_reader :description
      # Set of [key-value pairs](https://stripe.com/docs/api/metadata) that will set metadata on [Payment Intents](https://stripe.com/docs/api/payment_intents) generated from this payment link.
      attr_reader :metadata
      # Indicates that you intend to make future payments with the payment method collected during checkout.
      attr_reader :setup_future_usage
      # For a non-card payment, information about the charge that appears on the customer's statement when this payment succeeds in creating a charge.
      attr_reader :statement_descriptor
      # For a card payment, information about the charge that appears on the customer's statement when this payment succeeds in creating a charge. Concatenated with the account's statement descriptor prefix to form the complete statement descriptor.
      attr_reader :statement_descriptor_suffix
      # A string that identifies the resulting payment as part of a group. See the PaymentIntents [use case for connected accounts](https://stripe.com/docs/connect/separate-charges-and-transfers) for details.
      attr_reader :transfer_group

      def self.inner_class_types
        @inner_class_types = {}
      end

      def self.field_remappings
        @field_remappings = {}
      end
    end

    class PhoneNumberCollection < ::Stripe::StripeObject
      # If `true`, a phone number will be collected during checkout.
      attr_reader :enabled

      def self.inner_class_types
        @inner_class_types = {}
      end

      def self.field_remappings
        @field_remappings = {}
      end
    end

    class Restrictions < ::Stripe::StripeObject
      class CompletedSessions < ::Stripe::StripeObject
        # The current number of checkout sessions that have been completed on the payment link which count towards the `completed_sessions` restriction to be met.
        attr_reader :count
        # The maximum number of checkout sessions that can be completed for the `completed_sessions` restriction to be met.
        attr_reader :limit

        def self.inner_class_types
          @inner_class_types = {}
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end
      # Attribute for field completed_sessions
      attr_reader :completed_sessions

      def self.inner_class_types
        @inner_class_types = { completed_sessions: CompletedSessions }
      end

      def self.field_remappings
        @field_remappings = {}
      end
    end

    class ShippingAddressCollection < ::Stripe::StripeObject
      # An array of two-letter ISO country codes representing which countries Checkout should provide as options for shipping locations. Unsupported country codes: `AS, CX, CC, CU, HM, IR, KP, MH, FM, NF, MP, PW, SD, SY, UM, VI`.
      attr_reader :allowed_countries

      def self.inner_class_types
        @inner_class_types = {}
      end

      def self.field_remappings
        @field_remappings = {}
      end
    end

    class ShippingOption < ::Stripe::StripeObject
      # A non-negative integer in cents representing how much to charge.
      attr_reader :shipping_amount
      # The ID of the Shipping Rate to use for this shipping option.
      attr_reader :shipping_rate

      def self.inner_class_types
        @inner_class_types = {}
      end

      def self.field_remappings
        @field_remappings = {}
      end
    end

    class SubscriptionData < ::Stripe::StripeObject
      class InvoiceSettings < ::Stripe::StripeObject
        class Issuer < ::Stripe::StripeObject
          # The connected account being referenced when `type` is `account`.
          attr_reader :account
          # Type of the account referenced.
          attr_reader :type

          def self.inner_class_types
            @inner_class_types = {}
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end
        # Attribute for field issuer
        attr_reader :issuer

        def self.inner_class_types
          @inner_class_types = { issuer: Issuer }
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end

      class TrialSettings < ::Stripe::StripeObject
        class EndBehavior < ::Stripe::StripeObject
          # Indicates how the subscription should change when the trial ends if the user did not provide a payment method.
          attr_reader :missing_payment_method

          def self.inner_class_types
            @inner_class_types = {}
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end
        # Defines how a subscription behaves when a free trial ends.
        attr_reader :end_behavior

        def self.inner_class_types
          @inner_class_types = { end_behavior: EndBehavior }
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end
      # The subscription's description, meant to be displayable to the customer. Use this field to optionally store an explanation of the subscription for rendering in Stripe surfaces and certain local payment methods UIs.
      attr_reader :description
      # Attribute for field invoice_settings
      attr_reader :invoice_settings
      # Set of [key-value pairs](https://stripe.com/docs/api/metadata) that will set metadata on [Subscriptions](https://stripe.com/docs/api/subscriptions) generated from this payment link.
      attr_reader :metadata
      # Integer representing the number of trial period days before the customer is charged for the first time.
      attr_reader :trial_period_days
      # Settings related to subscription trials.
      attr_reader :trial_settings

      def self.inner_class_types
        @inner_class_types = { invoice_settings: InvoiceSettings, trial_settings: TrialSettings }
      end

      def self.field_remappings
        @field_remappings = {}
      end
    end

    class TaxIdCollection < ::Stripe::StripeObject
      # Indicates whether tax ID collection is enabled for the session.
      attr_reader :enabled
      # Attribute for field required
      attr_reader :required

      def self.inner_class_types
        @inner_class_types = {}
      end

      def self.field_remappings
        @field_remappings = {}
      end
    end

    class TransferData < ::Stripe::StripeObject
      # The amount in cents (or local equivalent) that will be transferred to the destination account. By default, the entire amount is transferred to the destination.
      attr_reader :amount
      # The connected account receiving the transfer.
      attr_reader :destination

      def self.inner_class_types
        @inner_class_types = {}
      end

      def self.field_remappings
        @field_remappings = {}
      end
    end
    # Whether the payment link's `url` is active. If `false`, customers visiting the URL will be shown a page saying that the link has been deactivated.
    attr_reader :active
    # Attribute for field after_completion
    attr_reader :after_completion
    # Whether user redeemable promotion codes are enabled.
    attr_reader :allow_promotion_codes
    # The ID of the Connect application that created the Payment Link.
    attr_reader :application
    # The amount of the application fee (if any) that will be requested to be applied to the payment and transferred to the application owner's Stripe account.
    attr_reader :application_fee_amount
    # This represents the percentage of the subscription invoice total that will be transferred to the application owner's Stripe account.
    attr_reader :application_fee_percent
    # Attribute for field automatic_tax
    attr_reader :automatic_tax
    # Configuration for collecting the customer's billing address. Defaults to `auto`.
    attr_reader :billing_address_collection
    # When set, provides configuration to gather active consent from customers.
    attr_reader :consent_collection
    # Three-letter [ISO currency code](https://www.iso.org/iso-4217-currency-codes.html), in lowercase. Must be a [supported currency](https://stripe.com/docs/currencies).
    attr_reader :currency
    # Collect additional information from your customer using custom fields. Up to 3 fields are supported.
    attr_reader :custom_fields
    # Attribute for field custom_text
    attr_reader :custom_text
    # Configuration for Customer creation during checkout.
    attr_reader :customer_creation
    # Unique identifier for the object.
    attr_reader :id
    # The custom message to be displayed to a customer when a payment link is no longer active.
    attr_reader :inactive_message
    # Configuration for creating invoice for payment mode payment links.
    attr_reader :invoice_creation
    # The line items representing what is being sold.
    attr_reader :line_items
    # Has the value `true` if the object exists in live mode or the value `false` if the object exists in test mode.
    attr_reader :livemode
    # Set of [key-value pairs](https://stripe.com/docs/api/metadata) that you can attach to an object. This can be useful for storing additional information about the object in a structured format.
    attr_reader :metadata
    # Attribute for field name_collection
    attr_reader :name_collection
    # String representing the object's type. Objects of the same type share the same value.
    attr_reader :object
    # The account on behalf of which to charge. See the [Connect documentation](https://support.stripe.com/questions/sending-invoices-on-behalf-of-connected-accounts) for details.
    attr_reader :on_behalf_of
    # The optional items presented to the customer at checkout.
    attr_reader :optional_items
    # Indicates the parameters to be passed to PaymentIntent creation during checkout.
    attr_reader :payment_intent_data
    # Configuration for collecting a payment method during checkout. Defaults to `always`.
    attr_reader :payment_method_collection
    # The list of payment method types that customers can use. When `null`, Stripe will dynamically show relevant payment methods you've enabled in your [payment method settings](https://dashboard.stripe.com/settings/payment_methods).
    attr_reader :payment_method_types
    # Attribute for field phone_number_collection
    attr_reader :phone_number_collection
    # Settings that restrict the usage of a payment link.
    attr_reader :restrictions
    # Configuration for collecting the customer's shipping address.
    attr_reader :shipping_address_collection
    # The shipping rate options applied to the session.
    attr_reader :shipping_options
    # Indicates the type of transaction being performed which customizes relevant text on the page, such as the submit button.
    attr_reader :submit_type
    # When creating a subscription, the specified configuration data will be used. There must be at least one line item with a recurring price to use `subscription_data`.
    attr_reader :subscription_data
    # Attribute for field tax_id_collection
    attr_reader :tax_id_collection
    # The account (if any) the payments will be attributed to for tax reporting, and where funds from each payment will be transferred to.
    attr_reader :transfer_data
    # The public URL that can be shared with customers.
    attr_reader :url

    # Creates a payment link.
    def self.create(params = {}, opts = {})
      request_stripe_object(method: :post, path: "/v1/payment_links", params: params, opts: opts)
    end

    # Returns a list of your payment links.
    def self.list(params = {}, opts = {})
      request_stripe_object(method: :get, path: "/v1/payment_links", params: params, opts: opts)
    end

    # When retrieving a payment link, there is an includable line_items property containing the first handful of those items. There is also a URL where you can retrieve the full (paginated) list of line items.
    def list_line_items(params = {}, opts = {})
      request_stripe_object(
        method: :get,
        path: format("/v1/payment_links/%<payment_link>s/line_items", { payment_link: CGI.escape(self["id"]) }),
        params: params,
        opts: opts
      )
    end

    # When retrieving a payment link, there is an includable line_items property containing the first handful of those items. There is also a URL where you can retrieve the full (paginated) list of line items.
    def self.list_line_items(payment_link, params = {}, opts = {})
      request_stripe_object(
        method: :get,
        path: format("/v1/payment_links/%<payment_link>s/line_items", { payment_link: CGI.escape(payment_link) }),
        params: params,
        opts: opts
      )
    end

    # Updates a payment link.
    def self.update(payment_link, params = {}, opts = {})
      request_stripe_object(
        method: :post,
        path: format("/v1/payment_links/%<payment_link>s", { payment_link: CGI.escape(payment_link) }),
        params: params,
        opts: opts
      )
    end

    def self.inner_class_types
      @inner_class_types = {
        after_completion: AfterCompletion,
        automatic_tax: AutomaticTax,
        consent_collection: ConsentCollection,
        custom_fields: CustomField,
        custom_text: CustomText,
        invoice_creation: InvoiceCreation,
        name_collection: NameCollection,
        optional_items: OptionalItem,
        payment_intent_data: PaymentIntentData,
        phone_number_collection: PhoneNumberCollection,
        restrictions: Restrictions,
        shipping_address_collection: ShippingAddressCollection,
        shipping_options: ShippingOption,
        subscription_data: SubscriptionData,
        tax_id_collection: TaxIdCollection,
        transfer_data: TransferData,
      }
    end

    def self.field_remappings
      @field_remappings = {}
    end
  end
end
