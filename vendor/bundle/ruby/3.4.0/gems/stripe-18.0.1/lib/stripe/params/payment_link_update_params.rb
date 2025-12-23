# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  class PaymentLinkUpdateParams < ::Stripe::RequestParams
    class AfterCompletion < ::Stripe::RequestParams
      class HostedConfirmation < ::Stripe::RequestParams
        # A custom message to display to the customer after the purchase is complete.
        attr_accessor :custom_message

        def initialize(custom_message: nil)
          @custom_message = custom_message
        end
      end

      class Redirect < ::Stripe::RequestParams
        # The URL the customer will be redirected to after the purchase is complete. You can embed `{CHECKOUT_SESSION_ID}` into the URL to have the `id` of the completed [checkout session](https://stripe.com/docs/api/checkout/sessions/object#checkout_session_object-id) included.
        attr_accessor :url

        def initialize(url: nil)
          @url = url
        end
      end
      # Configuration when `type=hosted_confirmation`.
      attr_accessor :hosted_confirmation
      # Configuration when `type=redirect`.
      attr_accessor :redirect
      # The specified behavior after the purchase is complete. Either `redirect` or `hosted_confirmation`.
      attr_accessor :type

      def initialize(hosted_confirmation: nil, redirect: nil, type: nil)
        @hosted_confirmation = hosted_confirmation
        @redirect = redirect
        @type = type
      end
    end

    class AutomaticTax < ::Stripe::RequestParams
      class Liability < ::Stripe::RequestParams
        # The connected account being referenced when `type` is `account`.
        attr_accessor :account
        # Type of the account referenced in the request.
        attr_accessor :type

        def initialize(account: nil, type: nil)
          @account = account
          @type = type
        end
      end
      # Set to `true` to [calculate tax automatically](https://docs.stripe.com/tax) using the customer's location.
      #
      # Enabling this parameter causes the payment link to collect any billing address information necessary for tax calculation.
      attr_accessor :enabled
      # The account that's liable for tax. If set, the business address and tax registrations required to perform the tax calculation are loaded from this account. The tax transaction is returned in the report of the connected account.
      attr_accessor :liability

      def initialize(enabled: nil, liability: nil)
        @enabled = enabled
        @liability = liability
      end
    end

    class CustomField < ::Stripe::RequestParams
      class Dropdown < ::Stripe::RequestParams
        class Option < ::Stripe::RequestParams
          # The label for the option, displayed to the customer. Up to 100 characters.
          attr_accessor :label
          # The value for this option, not displayed to the customer, used by your integration to reconcile the option selected by the customer. Must be unique to this option, alphanumeric, and up to 100 characters.
          attr_accessor :value

          def initialize(label: nil, value: nil)
            @label = label
            @value = value
          end
        end
        # The value that will pre-fill the field on the payment page.Must match a `value` in the `options` array.
        attr_accessor :default_value
        # The options available for the customer to select. Up to 200 options allowed.
        attr_accessor :options

        def initialize(default_value: nil, options: nil)
          @default_value = default_value
          @options = options
        end
      end

      class Label < ::Stripe::RequestParams
        # Custom text for the label, displayed to the customer. Up to 50 characters.
        attr_accessor :custom
        # The type of the label.
        attr_accessor :type

        def initialize(custom: nil, type: nil)
          @custom = custom
          @type = type
        end
      end

      class Numeric < ::Stripe::RequestParams
        # The value that will pre-fill the field on the payment page.
        attr_accessor :default_value
        # The maximum character length constraint for the customer's input.
        attr_accessor :maximum_length
        # The minimum character length requirement for the customer's input.
        attr_accessor :minimum_length

        def initialize(default_value: nil, maximum_length: nil, minimum_length: nil)
          @default_value = default_value
          @maximum_length = maximum_length
          @minimum_length = minimum_length
        end
      end

      class Text < ::Stripe::RequestParams
        # The value that will pre-fill the field on the payment page.
        attr_accessor :default_value
        # The maximum character length constraint for the customer's input.
        attr_accessor :maximum_length
        # The minimum character length requirement for the customer's input.
        attr_accessor :minimum_length

        def initialize(default_value: nil, maximum_length: nil, minimum_length: nil)
          @default_value = default_value
          @maximum_length = maximum_length
          @minimum_length = minimum_length
        end
      end
      # Configuration for `type=dropdown` fields.
      attr_accessor :dropdown
      # String of your choice that your integration can use to reconcile this field. Must be unique to this field, alphanumeric, and up to 200 characters.
      attr_accessor :key
      # The label for the field, displayed to the customer.
      attr_accessor :label
      # Configuration for `type=numeric` fields.
      attr_accessor :numeric
      # Whether the customer is required to complete the field before completing the Checkout Session. Defaults to `false`.
      attr_accessor :optional
      # Configuration for `type=text` fields.
      attr_accessor :text
      # The type of the field.
      attr_accessor :type

      def initialize(
        dropdown: nil,
        key: nil,
        label: nil,
        numeric: nil,
        optional: nil,
        text: nil,
        type: nil
      )
        @dropdown = dropdown
        @key = key
        @label = label
        @numeric = numeric
        @optional = optional
        @text = text
        @type = type
      end
    end

    class CustomText < ::Stripe::RequestParams
      class AfterSubmit < ::Stripe::RequestParams
        # Text may be up to 1200 characters in length.
        attr_accessor :message

        def initialize(message: nil)
          @message = message
        end
      end

      class ShippingAddress < ::Stripe::RequestParams
        # Text may be up to 1200 characters in length.
        attr_accessor :message

        def initialize(message: nil)
          @message = message
        end
      end

      class Submit < ::Stripe::RequestParams
        # Text may be up to 1200 characters in length.
        attr_accessor :message

        def initialize(message: nil)
          @message = message
        end
      end

      class TermsOfServiceAcceptance < ::Stripe::RequestParams
        # Text may be up to 1200 characters in length.
        attr_accessor :message

        def initialize(message: nil)
          @message = message
        end
      end
      # Custom text that should be displayed after the payment confirmation button.
      attr_accessor :after_submit
      # Custom text that should be displayed alongside shipping address collection.
      attr_accessor :shipping_address
      # Custom text that should be displayed alongside the payment confirmation button.
      attr_accessor :submit
      # Custom text that should be displayed in place of the default terms of service agreement text.
      attr_accessor :terms_of_service_acceptance

      def initialize(
        after_submit: nil,
        shipping_address: nil,
        submit: nil,
        terms_of_service_acceptance: nil
      )
        @after_submit = after_submit
        @shipping_address = shipping_address
        @submit = submit
        @terms_of_service_acceptance = terms_of_service_acceptance
      end
    end

    class InvoiceCreation < ::Stripe::RequestParams
      class InvoiceData < ::Stripe::RequestParams
        class CustomField < ::Stripe::RequestParams
          # The name of the custom field. This may be up to 40 characters.
          attr_accessor :name
          # The value of the custom field. This may be up to 140 characters.
          attr_accessor :value

          def initialize(name: nil, value: nil)
            @name = name
            @value = value
          end
        end

        class Issuer < ::Stripe::RequestParams
          # The connected account being referenced when `type` is `account`.
          attr_accessor :account
          # Type of the account referenced in the request.
          attr_accessor :type

          def initialize(account: nil, type: nil)
            @account = account
            @type = type
          end
        end

        class RenderingOptions < ::Stripe::RequestParams
          # How line-item prices and amounts will be displayed with respect to tax on invoice PDFs. One of `exclude_tax` or `include_inclusive_tax`. `include_inclusive_tax` will include inclusive tax (and exclude exclusive tax) in invoice PDF amounts. `exclude_tax` will exclude all tax (inclusive and exclusive alike) from invoice PDF amounts.
          attr_accessor :amount_tax_display
          # ID of the invoice rendering template to use for this invoice.
          attr_accessor :template

          def initialize(amount_tax_display: nil, template: nil)
            @amount_tax_display = amount_tax_display
            @template = template
          end
        end
        # The account tax IDs associated with the invoice.
        attr_accessor :account_tax_ids
        # Default custom fields to be displayed on invoices for this customer.
        attr_accessor :custom_fields
        # An arbitrary string attached to the object. Often useful for displaying to users.
        attr_accessor :description
        # Default footer to be displayed on invoices for this customer.
        attr_accessor :footer
        # The connected account that issues the invoice. The invoice is presented with the branding and support information of the specified account.
        attr_accessor :issuer
        # Set of [key-value pairs](https://stripe.com/docs/api/metadata) that you can attach to an object. This can be useful for storing additional information about the object in a structured format. Individual keys can be unset by posting an empty value to them. All keys can be unset by posting an empty value to `metadata`.
        attr_accessor :metadata
        # Default options for invoice PDF rendering for this customer.
        attr_accessor :rendering_options

        def initialize(
          account_tax_ids: nil,
          custom_fields: nil,
          description: nil,
          footer: nil,
          issuer: nil,
          metadata: nil,
          rendering_options: nil
        )
          @account_tax_ids = account_tax_ids
          @custom_fields = custom_fields
          @description = description
          @footer = footer
          @issuer = issuer
          @metadata = metadata
          @rendering_options = rendering_options
        end
      end
      # Whether the feature is enabled
      attr_accessor :enabled
      # Invoice PDF configuration.
      attr_accessor :invoice_data

      def initialize(enabled: nil, invoice_data: nil)
        @enabled = enabled
        @invoice_data = invoice_data
      end
    end

    class LineItem < ::Stripe::RequestParams
      class AdjustableQuantity < ::Stripe::RequestParams
        # Set to true if the quantity can be adjusted to any non-negative Integer.
        attr_accessor :enabled
        # The maximum quantity the customer can purchase. By default this value is 99. You can specify a value up to 999999.
        attr_accessor :maximum
        # The minimum quantity the customer can purchase. By default this value is 0. If there is only one item in the cart then that item's quantity cannot go down to 0.
        attr_accessor :minimum

        def initialize(enabled: nil, maximum: nil, minimum: nil)
          @enabled = enabled
          @maximum = maximum
          @minimum = minimum
        end
      end
      # When set, provides configuration for this item’s quantity to be adjusted by the customer during checkout.
      attr_accessor :adjustable_quantity
      # The ID of an existing line item on the payment link.
      attr_accessor :id
      # The quantity of the line item being purchased.
      attr_accessor :quantity

      def initialize(adjustable_quantity: nil, id: nil, quantity: nil)
        @adjustable_quantity = adjustable_quantity
        @id = id
        @quantity = quantity
      end
    end

    class NameCollection < ::Stripe::RequestParams
      class Business < ::Stripe::RequestParams
        # Enable business name collection on the payment link. Defaults to `false`.
        attr_accessor :enabled
        # Whether the customer is required to provide their business name before checking out. Defaults to `false`.
        attr_accessor :optional

        def initialize(enabled: nil, optional: nil)
          @enabled = enabled
          @optional = optional
        end
      end

      class Individual < ::Stripe::RequestParams
        # Enable individual name collection on the payment link. Defaults to `false`.
        attr_accessor :enabled
        # Whether the customer is required to provide their full name before checking out. Defaults to `false`.
        attr_accessor :optional

        def initialize(enabled: nil, optional: nil)
          @enabled = enabled
          @optional = optional
        end
      end
      # Controls settings applied for collecting the customer's business name.
      attr_accessor :business
      # Controls settings applied for collecting the customer's individual name.
      attr_accessor :individual

      def initialize(business: nil, individual: nil)
        @business = business
        @individual = individual
      end
    end

    class PaymentIntentData < ::Stripe::RequestParams
      # An arbitrary string attached to the object. Often useful for displaying to users.
      attr_accessor :description
      # Set of [key-value pairs](https://stripe.com/docs/api/metadata) that will declaratively set metadata on [Payment Intents](https://stripe.com/docs/api/payment_intents) generated from this payment link. Unlike object-level metadata, this field is declarative. Updates will clear prior values.
      attr_accessor :metadata
      # Text that appears on the customer's statement as the statement descriptor for a non-card charge. This value overrides the account's default statement descriptor. For information about requirements, including the 22-character limit, see [the Statement Descriptor docs](https://docs.stripe.com/get-started/account/statement-descriptors).
      #
      # Setting this value for a card charge returns an error. For card charges, set the [statement_descriptor_suffix](https://docs.stripe.com/get-started/account/statement-descriptors#dynamic) instead.
      attr_accessor :statement_descriptor
      # Provides information about a card charge. Concatenated to the account's [statement descriptor prefix](https://docs.stripe.com/get-started/account/statement-descriptors#static) to form the complete statement descriptor that appears on the customer's statement.
      attr_accessor :statement_descriptor_suffix
      # A string that identifies the resulting payment as part of a group. See the PaymentIntents [use case for connected accounts](https://stripe.com/docs/connect/separate-charges-and-transfers) for details.
      attr_accessor :transfer_group

      def initialize(
        description: nil,
        metadata: nil,
        statement_descriptor: nil,
        statement_descriptor_suffix: nil,
        transfer_group: nil
      )
        @description = description
        @metadata = metadata
        @statement_descriptor = statement_descriptor
        @statement_descriptor_suffix = statement_descriptor_suffix
        @transfer_group = transfer_group
      end
    end

    class PhoneNumberCollection < ::Stripe::RequestParams
      # Set to `true` to enable phone number collection.
      attr_accessor :enabled

      def initialize(enabled: nil)
        @enabled = enabled
      end
    end

    class Restrictions < ::Stripe::RequestParams
      class CompletedSessions < ::Stripe::RequestParams
        # The maximum number of checkout sessions that can be completed for the `completed_sessions` restriction to be met.
        attr_accessor :limit

        def initialize(limit: nil)
          @limit = limit
        end
      end
      # Configuration for the `completed_sessions` restriction type.
      attr_accessor :completed_sessions

      def initialize(completed_sessions: nil)
        @completed_sessions = completed_sessions
      end
    end

    class ShippingAddressCollection < ::Stripe::RequestParams
      # An array of two-letter ISO country codes representing which countries Checkout should provide as options for
      # shipping locations.
      attr_accessor :allowed_countries

      def initialize(allowed_countries: nil)
        @allowed_countries = allowed_countries
      end
    end

    class SubscriptionData < ::Stripe::RequestParams
      class InvoiceSettings < ::Stripe::RequestParams
        class Issuer < ::Stripe::RequestParams
          # The connected account being referenced when `type` is `account`.
          attr_accessor :account
          # Type of the account referenced in the request.
          attr_accessor :type

          def initialize(account: nil, type: nil)
            @account = account
            @type = type
          end
        end
        # The connected account that issues the invoice. The invoice is presented with the branding and support information of the specified account.
        attr_accessor :issuer

        def initialize(issuer: nil)
          @issuer = issuer
        end
      end

      class TrialSettings < ::Stripe::RequestParams
        class EndBehavior < ::Stripe::RequestParams
          # Indicates how the subscription should change when the trial ends if the user did not provide a payment method.
          attr_accessor :missing_payment_method

          def initialize(missing_payment_method: nil)
            @missing_payment_method = missing_payment_method
          end
        end
        # Defines how the subscription should behave when the user's free trial ends.
        attr_accessor :end_behavior

        def initialize(end_behavior: nil)
          @end_behavior = end_behavior
        end
      end
      # All invoices will be billed using the specified settings.
      attr_accessor :invoice_settings
      # Set of [key-value pairs](https://stripe.com/docs/api/metadata) that will declaratively set metadata on [Subscriptions](https://stripe.com/docs/api/subscriptions) generated from this payment link. Unlike object-level metadata, this field is declarative. Updates will clear prior values.
      attr_accessor :metadata
      # Integer representing the number of trial period days before the customer is charged for the first time. Has to be at least 1.
      attr_accessor :trial_period_days
      # Settings related to subscription trials.
      attr_accessor :trial_settings

      def initialize(
        invoice_settings: nil,
        metadata: nil,
        trial_period_days: nil,
        trial_settings: nil
      )
        @invoice_settings = invoice_settings
        @metadata = metadata
        @trial_period_days = trial_period_days
        @trial_settings = trial_settings
      end
    end

    class TaxIdCollection < ::Stripe::RequestParams
      # Enable tax ID collection during checkout. Defaults to `false`.
      attr_accessor :enabled
      # Describes whether a tax ID is required during checkout. Defaults to `never`.
      attr_accessor :required

      def initialize(enabled: nil, required: nil)
        @enabled = enabled
        @required = required
      end
    end
    # Whether the payment link's `url` is active. If `false`, customers visiting the URL will be shown a page saying that the link has been deactivated.
    attr_accessor :active
    # Behavior after the purchase is complete.
    attr_accessor :after_completion
    # Enables user redeemable promotion codes.
    attr_accessor :allow_promotion_codes
    # Configuration for automatic tax collection.
    attr_accessor :automatic_tax
    # Configuration for collecting the customer's billing address. Defaults to `auto`.
    attr_accessor :billing_address_collection
    # Collect additional information from your customer using custom fields. Up to 3 fields are supported.
    attr_accessor :custom_fields
    # Display additional text for your customers using custom text.
    attr_accessor :custom_text
    # Configures whether [checkout sessions](https://stripe.com/docs/api/checkout/sessions) created by this payment link create a [Customer](https://stripe.com/docs/api/customers).
    attr_accessor :customer_creation
    # Specifies which fields in the response should be expanded.
    attr_accessor :expand
    # The custom message to be displayed to a customer when a payment link is no longer active.
    attr_accessor :inactive_message
    # Generate a post-purchase Invoice for one-time payments.
    attr_accessor :invoice_creation
    # The line items representing what is being sold. Each line item represents an item being sold. Up to 20 line items are supported.
    attr_accessor :line_items
    # Set of [key-value pairs](https://stripe.com/docs/api/metadata) that you can attach to an object. This can be useful for storing additional information about the object in a structured format. Individual keys can be unset by posting an empty value to them. All keys can be unset by posting an empty value to `metadata`. Metadata associated with this Payment Link will automatically be copied to [checkout sessions](https://stripe.com/docs/api/checkout/sessions) created by this payment link.
    attr_accessor :metadata
    # Controls settings applied for collecting the customer's name.
    attr_accessor :name_collection
    # A subset of parameters to be passed to PaymentIntent creation for Checkout Sessions in `payment` mode.
    attr_accessor :payment_intent_data
    # Specify whether Checkout should collect a payment method. When set to `if_required`, Checkout will not collect a payment method when the total due for the session is 0.This may occur if the Checkout Session includes a free trial or a discount.
    #
    # Can only be set in `subscription` mode. Defaults to `always`.
    #
    # If you'd like information on how to collect a payment method outside of Checkout, read the guide on [configuring subscriptions with a free trial](https://stripe.com/docs/payments/checkout/free-trials).
    attr_accessor :payment_method_collection
    # The list of payment method types that customers can use. Pass an empty string to enable dynamic payment methods that use your [payment method settings](https://dashboard.stripe.com/settings/payment_methods).
    attr_accessor :payment_method_types
    # Controls phone number collection settings during checkout.
    #
    # We recommend that you review your privacy policy and check with your legal contacts.
    attr_accessor :phone_number_collection
    # Settings that restrict the usage of a payment link.
    attr_accessor :restrictions
    # Configuration for collecting the customer's shipping address.
    attr_accessor :shipping_address_collection
    # Describes the type of transaction being performed in order to customize relevant text on the page, such as the submit button. Changing this value will also affect the hostname in the [url](https://stripe.com/docs/api/payment_links/payment_links/object#url) property (example: `donate.stripe.com`).
    attr_accessor :submit_type
    # When creating a subscription, the specified configuration data will be used. There must be at least one line item with a recurring price to use `subscription_data`.
    attr_accessor :subscription_data
    # Controls tax ID collection during checkout.
    attr_accessor :tax_id_collection

    def initialize(
      active: nil,
      after_completion: nil,
      allow_promotion_codes: nil,
      automatic_tax: nil,
      billing_address_collection: nil,
      custom_fields: nil,
      custom_text: nil,
      customer_creation: nil,
      expand: nil,
      inactive_message: nil,
      invoice_creation: nil,
      line_items: nil,
      metadata: nil,
      name_collection: nil,
      payment_intent_data: nil,
      payment_method_collection: nil,
      payment_method_types: nil,
      phone_number_collection: nil,
      restrictions: nil,
      shipping_address_collection: nil,
      submit_type: nil,
      subscription_data: nil,
      tax_id_collection: nil
    )
      @active = active
      @after_completion = after_completion
      @allow_promotion_codes = allow_promotion_codes
      @automatic_tax = automatic_tax
      @billing_address_collection = billing_address_collection
      @custom_fields = custom_fields
      @custom_text = custom_text
      @customer_creation = customer_creation
      @expand = expand
      @inactive_message = inactive_message
      @invoice_creation = invoice_creation
      @line_items = line_items
      @metadata = metadata
      @name_collection = name_collection
      @payment_intent_data = payment_intent_data
      @payment_method_collection = payment_method_collection
      @payment_method_types = payment_method_types
      @phone_number_collection = phone_number_collection
      @restrictions = restrictions
      @shipping_address_collection = shipping_address_collection
      @submit_type = submit_type
      @subscription_data = subscription_data
      @tax_id_collection = tax_id_collection
    end
  end
end
