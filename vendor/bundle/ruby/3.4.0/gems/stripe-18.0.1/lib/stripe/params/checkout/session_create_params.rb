# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  module Checkout
    class SessionCreateParams < ::Stripe::RequestParams
      class AdaptivePricing < ::Stripe::RequestParams
        # If set to `true`, Adaptive Pricing is available on [eligible sessions](https://docs.stripe.com/payments/currencies/localize-prices/adaptive-pricing?payment-ui=stripe-hosted#restrictions). Defaults to your [dashboard setting](https://dashboard.stripe.com/settings/adaptive-pricing).
        attr_accessor :enabled

        def initialize(enabled: nil)
          @enabled = enabled
        end
      end

      class AfterExpiration < ::Stripe::RequestParams
        class Recovery < ::Stripe::RequestParams
          # Enables user redeemable promotion codes on the recovered Checkout Sessions. Defaults to `false`
          attr_accessor :allow_promotion_codes
          # If `true`, a recovery URL will be generated to recover this Checkout Session if it
          # expires before a successful transaction is completed. It will be attached to the
          # Checkout Session object upon expiration.
          attr_accessor :enabled

          def initialize(allow_promotion_codes: nil, enabled: nil)
            @allow_promotion_codes = allow_promotion_codes
            @enabled = enabled
          end
        end
        # Configure a Checkout Session that can be used to recover an expired session.
        attr_accessor :recovery

        def initialize(recovery: nil)
          @recovery = recovery
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
        # Enabling this parameter causes Checkout to collect any billing address information necessary for tax calculation.
        attr_accessor :enabled
        # The account that's liable for tax. If set, the business address and tax registrations required to perform the tax calculation are loaded from this account. The tax transaction is returned in the report of the connected account.
        attr_accessor :liability

        def initialize(enabled: nil, liability: nil)
          @enabled = enabled
          @liability = liability
        end
      end

      class BrandingSettings < ::Stripe::RequestParams
        class Icon < ::Stripe::RequestParams
          # The ID of a [File upload](https://stripe.com/docs/api/files) representing the icon. Purpose must be `business_icon`. Required if `type` is `file` and disallowed otherwise.
          attr_accessor :file
          # The type of image for the icon. Must be one of `file` or `url`.
          attr_accessor :type
          # The URL of the image. Required if `type` is `url` and disallowed otherwise.
          attr_accessor :url

          def initialize(file: nil, type: nil, url: nil)
            @file = file
            @type = type
            @url = url
          end
        end

        class Logo < ::Stripe::RequestParams
          # The ID of a [File upload](https://stripe.com/docs/api/files) representing the logo. Purpose must be `business_logo`. Required if `type` is `file` and disallowed otherwise.
          attr_accessor :file
          # The type of image for the logo. Must be one of `file` or `url`.
          attr_accessor :type
          # The URL of the image. Required if `type` is `url` and disallowed otherwise.
          attr_accessor :url

          def initialize(file: nil, type: nil, url: nil)
            @file = file
            @type = type
            @url = url
          end
        end
        # A hex color value starting with `#` representing the background color for the Checkout Session.
        attr_accessor :background_color
        # The border style for the Checkout Session.
        attr_accessor :border_style
        # A hex color value starting with `#` representing the button color for the Checkout Session.
        attr_accessor :button_color
        # A string to override the business name shown on the Checkout Session. This only shows at the top of the Checkout page, and your business name still appears in terms, receipts, and other places.
        attr_accessor :display_name
        # The font family for the Checkout Session corresponding to one of the [supported font families](https://docs.stripe.com/payments/checkout/customization/appearance?payment-ui=stripe-hosted#font-compatibility).
        attr_accessor :font_family
        # The icon for the Checkout Session. For best results, use a square image.
        attr_accessor :icon
        # The logo for the Checkout Session.
        attr_accessor :logo

        def initialize(
          background_color: nil,
          border_style: nil,
          button_color: nil,
          display_name: nil,
          font_family: nil,
          icon: nil,
          logo: nil
        )
          @background_color = background_color
          @border_style = border_style
          @button_color = button_color
          @display_name = display_name
          @font_family = font_family
          @icon = icon
          @logo = logo
        end
      end

      class ConsentCollection < ::Stripe::RequestParams
        class PaymentMethodReuseAgreement < ::Stripe::RequestParams
          # Determines the position and visibility of the payment method reuse agreement in the UI. When set to `auto`, Stripe's
          # defaults will be used. When set to `hidden`, the payment method reuse agreement text will always be hidden in the UI.
          attr_accessor :position

          def initialize(position: nil)
            @position = position
          end
        end
        # Determines the display of payment method reuse agreement text in the UI. If set to `hidden`, it will hide legal text related to the reuse of a payment method.
        attr_accessor :payment_method_reuse_agreement
        # If set to `auto`, enables the collection of customer consent for promotional communications. The Checkout
        # Session will determine whether to display an option to opt into promotional communication
        # from the merchant depending on the customer's locale. Only available to US merchants.
        attr_accessor :promotions
        # If set to `required`, it requires customers to check a terms of service checkbox before being able to pay.
        # There must be a valid terms of service URL set in your [Dashboard settings](https://dashboard.stripe.com/settings/public).
        attr_accessor :terms_of_service

        def initialize(payment_method_reuse_agreement: nil, promotions: nil, terms_of_service: nil)
          @payment_method_reuse_agreement = payment_method_reuse_agreement
          @promotions = promotions
          @terms_of_service = terms_of_service
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

      class CustomerUpdate < ::Stripe::RequestParams
        # Describes whether Checkout saves the billing address onto `customer.address`.
        # To always collect a full billing address, use `billing_address_collection`. Defaults to `never`.
        attr_accessor :address
        # Describes whether Checkout saves the name onto `customer.name`. Defaults to `never`.
        attr_accessor :name
        # Describes whether Checkout saves shipping information onto `customer.shipping`.
        # To collect shipping information, use `shipping_address_collection`. Defaults to `never`.
        attr_accessor :shipping

        def initialize(address: nil, name: nil, shipping: nil)
          @address = address
          @name = name
          @shipping = shipping
        end
      end

      class Discount < ::Stripe::RequestParams
        # The ID of the coupon to apply to this Session.
        attr_accessor :coupon
        # The ID of a promotion code to apply to this Session.
        attr_accessor :promotion_code

        def initialize(coupon: nil, promotion_code: nil)
          @coupon = coupon
          @promotion_code = promotion_code
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
        # Set to `true` to enable invoice creation.
        attr_accessor :enabled
        # Parameters passed when creating invoices for payment-mode Checkout Sessions.
        attr_accessor :invoice_data

        def initialize(enabled: nil, invoice_data: nil)
          @enabled = enabled
          @invoice_data = invoice_data
        end
      end

      class LineItem < ::Stripe::RequestParams
        class AdjustableQuantity < ::Stripe::RequestParams
          # Set to true if the quantity can be adjusted to any non-negative integer.
          attr_accessor :enabled
          # The maximum quantity the customer can purchase for the Checkout Session. By default this value is 99. You can specify a value up to 999999.
          attr_accessor :maximum
          # The minimum quantity the customer must purchase for the Checkout Session. By default this value is 0.
          attr_accessor :minimum

          def initialize(enabled: nil, maximum: nil, minimum: nil)
            @enabled = enabled
            @maximum = maximum
            @minimum = minimum
          end
        end

        class PriceData < ::Stripe::RequestParams
          class ProductData < ::Stripe::RequestParams
            # The product's description, meant to be displayable to the customer. Use this field to optionally store a long form explanation of the product being sold for your own rendering purposes.
            attr_accessor :description
            # A list of up to 8 URLs of images for this product, meant to be displayable to the customer.
            attr_accessor :images
            # Set of [key-value pairs](https://stripe.com/docs/api/metadata) that you can attach to an object. This can be useful for storing additional information about the object in a structured format. Individual keys can be unset by posting an empty value to them. All keys can be unset by posting an empty value to `metadata`.
            attr_accessor :metadata
            # The product's name, meant to be displayable to the customer.
            attr_accessor :name
            # A [tax code](https://stripe.com/docs/tax/tax-categories) ID.
            attr_accessor :tax_code
            # A label that represents units of this product. When set, this will be included in customers' receipts, invoices, Checkout, and the customer portal.
            attr_accessor :unit_label

            def initialize(
              description: nil,
              images: nil,
              metadata: nil,
              name: nil,
              tax_code: nil,
              unit_label: nil
            )
              @description = description
              @images = images
              @metadata = metadata
              @name = name
              @tax_code = tax_code
              @unit_label = unit_label
            end
          end

          class Recurring < ::Stripe::RequestParams
            # Specifies billing frequency. Either `day`, `week`, `month` or `year`.
            attr_accessor :interval
            # The number of intervals between subscription billings. For example, `interval=month` and `interval_count=3` bills every 3 months. Maximum of three years interval allowed (3 years, 36 months, or 156 weeks).
            attr_accessor :interval_count

            def initialize(interval: nil, interval_count: nil)
              @interval = interval
              @interval_count = interval_count
            end
          end
          # Three-letter [ISO currency code](https://www.iso.org/iso-4217-currency-codes.html), in lowercase. Must be a [supported currency](https://stripe.com/docs/currencies).
          attr_accessor :currency
          # The ID of the [Product](https://docs.stripe.com/api/products) that this [Price](https://docs.stripe.com/api/prices) will belong to. One of `product` or `product_data` is required.
          attr_accessor :product
          # Data used to generate a new [Product](https://docs.stripe.com/api/products) object inline. One of `product` or `product_data` is required.
          attr_accessor :product_data
          # The recurring components of a price such as `interval` and `interval_count`.
          attr_accessor :recurring
          # Only required if a [default tax behavior](https://stripe.com/docs/tax/products-prices-tax-categories-tax-behavior#setting-a-default-tax-behavior-(recommended)) was not provided in the Stripe Tax settings. Specifies whether the price is considered inclusive of taxes or exclusive of taxes. One of `inclusive`, `exclusive`, or `unspecified`. Once specified as either `inclusive` or `exclusive`, it cannot be changed.
          attr_accessor :tax_behavior
          # A non-negative integer in cents (or local equivalent) representing how much to charge. One of `unit_amount` or `unit_amount_decimal` is required.
          attr_accessor :unit_amount
          # Same as `unit_amount`, but accepts a decimal value in cents (or local equivalent) with at most 12 decimal places. Only one of `unit_amount` and `unit_amount_decimal` can be set.
          attr_accessor :unit_amount_decimal

          def initialize(
            currency: nil,
            product: nil,
            product_data: nil,
            recurring: nil,
            tax_behavior: nil,
            unit_amount: nil,
            unit_amount_decimal: nil
          )
            @currency = currency
            @product = product
            @product_data = product_data
            @recurring = recurring
            @tax_behavior = tax_behavior
            @unit_amount = unit_amount
            @unit_amount_decimal = unit_amount_decimal
          end
        end
        # When set, provides configuration for this item’s quantity to be adjusted by the customer during Checkout.
        attr_accessor :adjustable_quantity
        # The [tax rates](https://stripe.com/docs/api/tax_rates) that will be applied to this line item depending on the customer's billing/shipping address. We currently support the following countries: US, GB, AU, and all countries in the EU.
        attr_accessor :dynamic_tax_rates
        # The ID of the [Price](https://stripe.com/docs/api/prices) or [Plan](https://stripe.com/docs/api/plans) object. One of `price` or `price_data` is required.
        attr_accessor :price
        # Data used to generate a new [Price](https://stripe.com/docs/api/prices) object inline. One of `price` or `price_data` is required.
        attr_accessor :price_data
        # The quantity of the line item being purchased. Quantity should not be defined when `recurring.usage_type=metered`.
        attr_accessor :quantity
        # The [tax rates](https://stripe.com/docs/api/tax_rates) which apply to this line item.
        attr_accessor :tax_rates

        def initialize(
          adjustable_quantity: nil,
          dynamic_tax_rates: nil,
          price: nil,
          price_data: nil,
          quantity: nil,
          tax_rates: nil
        )
          @adjustable_quantity = adjustable_quantity
          @dynamic_tax_rates = dynamic_tax_rates
          @price = price
          @price_data = price_data
          @quantity = quantity
          @tax_rates = tax_rates
        end
      end

      class NameCollection < ::Stripe::RequestParams
        class Business < ::Stripe::RequestParams
          # Enable business name collection on the Checkout Session. Defaults to `false`.
          attr_accessor :enabled
          # Whether the customer is required to provide a business name before completing the Checkout Session. Defaults to `false`.
          attr_accessor :optional

          def initialize(enabled: nil, optional: nil)
            @enabled = enabled
            @optional = optional
          end
        end

        class Individual < ::Stripe::RequestParams
          # Enable individual name collection on the Checkout Session. Defaults to `false`.
          attr_accessor :enabled
          # Whether the customer is required to provide their name before completing the Checkout Session. Defaults to `false`.
          attr_accessor :optional

          def initialize(enabled: nil, optional: nil)
            @enabled = enabled
            @optional = optional
          end
        end
        # Controls settings applied for collecting the customer's business name on the session.
        attr_accessor :business
        # Controls settings applied for collecting the customer's individual name on the session.
        attr_accessor :individual

        def initialize(business: nil, individual: nil)
          @business = business
          @individual = individual
        end
      end

      class OptionalItem < ::Stripe::RequestParams
        class AdjustableQuantity < ::Stripe::RequestParams
          # Set to true if the quantity can be adjusted to any non-negative integer.
          attr_accessor :enabled
          # The maximum quantity of this item the customer can purchase. By default this value is 99. You can specify a value up to 999999.
          attr_accessor :maximum
          # The minimum quantity of this item the customer must purchase, if they choose to purchase it. Because this item is optional, the customer will always be able to remove it from their order, even if the `minimum` configured here is greater than 0. By default this value is 0.
          attr_accessor :minimum

          def initialize(enabled: nil, maximum: nil, minimum: nil)
            @enabled = enabled
            @maximum = maximum
            @minimum = minimum
          end
        end
        # When set, provides configuration for the customer to adjust the quantity of the line item created when a customer chooses to add this optional item to their order.
        attr_accessor :adjustable_quantity
        # The ID of the [Price](https://stripe.com/docs/api/prices) or [Plan](https://stripe.com/docs/api/plans) object.
        attr_accessor :price
        # The initial quantity of the line item created when a customer chooses to add this optional item to their order.
        attr_accessor :quantity

        def initialize(adjustable_quantity: nil, price: nil, quantity: nil)
          @adjustable_quantity = adjustable_quantity
          @price = price
          @quantity = quantity
        end
      end

      class PaymentIntentData < ::Stripe::RequestParams
        class Shipping < ::Stripe::RequestParams
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
          # Shipping address.
          attr_accessor :address
          # The delivery service that shipped a physical product, such as Fedex, UPS, USPS, etc.
          attr_accessor :carrier
          # Recipient name.
          attr_accessor :name
          # Recipient phone (including extension).
          attr_accessor :phone
          # The tracking number for a physical product, obtained from the delivery service. If multiple tracking numbers were generated for this purchase, please separate them with commas.
          attr_accessor :tracking_number

          def initialize(address: nil, carrier: nil, name: nil, phone: nil, tracking_number: nil)
            @address = address
            @carrier = carrier
            @name = name
            @phone = phone
            @tracking_number = tracking_number
          end
        end

        class TransferData < ::Stripe::RequestParams
          # The amount that will be transferred automatically when a charge succeeds.
          attr_accessor :amount
          # If specified, successful charges will be attributed to the destination
          # account for tax reporting, and the funds from charges will be transferred
          # to the destination account. The ID of the resulting transfer will be
          # returned on the successful charge's `transfer` field.
          attr_accessor :destination

          def initialize(amount: nil, destination: nil)
            @amount = amount
            @destination = destination
          end
        end
        # The amount of the application fee (if any) that will be requested to be applied to the payment and transferred to the application owner's Stripe account. The amount of the application fee collected will be capped at the total amount captured. For more information, see the PaymentIntents [use case for connected accounts](https://stripe.com/docs/payments/connected-accounts).
        attr_accessor :application_fee_amount
        # Controls when the funds will be captured from the customer's account.
        attr_accessor :capture_method
        # An arbitrary string attached to the object. Often useful for displaying to users.
        attr_accessor :description
        # Set of [key-value pairs](https://stripe.com/docs/api/metadata) that you can attach to an object. This can be useful for storing additional information about the object in a structured format. Individual keys can be unset by posting an empty value to them. All keys can be unset by posting an empty value to `metadata`.
        attr_accessor :metadata
        # The Stripe account ID for which these funds are intended. For details,
        # see the PaymentIntents [use case for connected
        # accounts](/docs/payments/connected-accounts).
        attr_accessor :on_behalf_of
        # Email address that the receipt for the resulting payment will be sent to. If `receipt_email` is specified for a payment in live mode, a receipt will be sent regardless of your [email settings](https://dashboard.stripe.com/account/emails).
        attr_accessor :receipt_email
        # Indicates that you intend to [make future payments](https://stripe.com/docs/payments/payment-intents#future-usage) with the payment
        # method collected by this Checkout Session.
        #
        # When setting this to `on_session`, Checkout will show a notice to the
        # customer that their payment details will be saved.
        #
        # When setting this to `off_session`, Checkout will show a notice to the
        # customer that their payment details will be saved and used for future
        # payments.
        #
        # If a Customer has been provided or Checkout creates a new Customer,
        # Checkout will attach the payment method to the Customer.
        #
        # If Checkout does not create a Customer, the payment method is not attached
        # to a Customer. To reuse the payment method, you can retrieve it from the
        # Checkout Session's PaymentIntent.
        #
        # When processing card payments, Checkout also uses `setup_future_usage`
        # to dynamically optimize your payment flow and comply with regional
        # legislation and network rules, such as SCA.
        attr_accessor :setup_future_usage
        # Shipping information for this payment.
        attr_accessor :shipping
        # Text that appears on the customer's statement as the statement descriptor for a non-card charge. This value overrides the account's default statement descriptor. For information about requirements, including the 22-character limit, see [the Statement Descriptor docs](https://docs.stripe.com/get-started/account/statement-descriptors).
        #
        # Setting this value for a card charge returns an error. For card charges, set the [statement_descriptor_suffix](https://docs.stripe.com/get-started/account/statement-descriptors#dynamic) instead.
        attr_accessor :statement_descriptor
        # Provides information about a card charge. Concatenated to the account's [statement descriptor prefix](https://docs.stripe.com/get-started/account/statement-descriptors#static) to form the complete statement descriptor that appears on the customer's statement.
        attr_accessor :statement_descriptor_suffix
        # The parameters used to automatically create a Transfer when the payment succeeds.
        # For more information, see the PaymentIntents [use case for connected accounts](https://stripe.com/docs/payments/connected-accounts).
        attr_accessor :transfer_data
        # A string that identifies the resulting payment as part of a group. See the PaymentIntents [use case for connected accounts](https://stripe.com/docs/connect/separate-charges-and-transfers) for details.
        attr_accessor :transfer_group

        def initialize(
          application_fee_amount: nil,
          capture_method: nil,
          description: nil,
          metadata: nil,
          on_behalf_of: nil,
          receipt_email: nil,
          setup_future_usage: nil,
          shipping: nil,
          statement_descriptor: nil,
          statement_descriptor_suffix: nil,
          transfer_data: nil,
          transfer_group: nil
        )
          @application_fee_amount = application_fee_amount
          @capture_method = capture_method
          @description = description
          @metadata = metadata
          @on_behalf_of = on_behalf_of
          @receipt_email = receipt_email
          @setup_future_usage = setup_future_usage
          @shipping = shipping
          @statement_descriptor = statement_descriptor
          @statement_descriptor_suffix = statement_descriptor_suffix
          @transfer_data = transfer_data
          @transfer_group = transfer_group
        end
      end

      class PaymentMethodData < ::Stripe::RequestParams
        # Allow redisplay will be set on the payment method on confirmation and indicates whether this payment method can be shown again to the customer in a checkout flow. Only set this field if you wish to override the allow_redisplay value determined by Checkout.
        attr_accessor :allow_redisplay

        def initialize(allow_redisplay: nil)
          @allow_redisplay = allow_redisplay
        end
      end

      class PaymentMethodOptions < ::Stripe::RequestParams
        class AcssDebit < ::Stripe::RequestParams
          class MandateOptions < ::Stripe::RequestParams
            # A URL for custom mandate text to render during confirmation step.
            # The URL will be rendered with additional GET parameters `payment_intent` and `payment_intent_client_secret` when confirming a Payment Intent,
            # or `setup_intent` and `setup_intent_client_secret` when confirming a Setup Intent.
            attr_accessor :custom_mandate_url
            # List of Stripe products where this mandate can be selected automatically. Only usable in `setup` mode.
            attr_accessor :default_for
            # Description of the mandate interval. Only required if 'payment_schedule' parameter is 'interval' or 'combined'.
            attr_accessor :interval_description
            # Payment schedule for the mandate.
            attr_accessor :payment_schedule
            # Transaction type of the mandate.
            attr_accessor :transaction_type

            def initialize(
              custom_mandate_url: nil,
              default_for: nil,
              interval_description: nil,
              payment_schedule: nil,
              transaction_type: nil
            )
              @custom_mandate_url = custom_mandate_url
              @default_for = default_for
              @interval_description = interval_description
              @payment_schedule = payment_schedule
              @transaction_type = transaction_type
            end
          end
          # Three-letter [ISO currency code](https://www.iso.org/iso-4217-currency-codes.html), in lowercase. Must be a [supported currency](https://stripe.com/docs/currencies). This is only accepted for Checkout Sessions in `setup` mode.
          attr_accessor :currency
          # Additional fields for Mandate creation
          attr_accessor :mandate_options
          # Indicates that you intend to make future payments with this PaymentIntent's payment method.
          #
          # If you provide a Customer with the PaymentIntent, you can use this parameter to [attach the payment method](/payments/save-during-payment) to the Customer after the PaymentIntent is confirmed and the customer completes any required actions. If you don't provide a Customer, you can still [attach](/api/payment_methods/attach) the payment method to a Customer after the transaction completes.
          #
          # If the payment method is `card_present` and isn't a digital wallet, Stripe creates and attaches a [generated_card](/api/charges/object#charge_object-payment_method_details-card_present-generated_card) payment method representing the card to the Customer instead.
          #
          # When processing card payments, Stripe uses `setup_future_usage` to help you comply with regional legislation and network rules, such as [SCA](/strong-customer-authentication).
          attr_accessor :setup_future_usage
          # Controls when Stripe will attempt to debit the funds from the customer's account. The date must be a string in YYYY-MM-DD format. The date must be in the future and between 3 and 15 calendar days from now.
          attr_accessor :target_date
          # Verification method for the intent
          attr_accessor :verification_method

          def initialize(
            currency: nil,
            mandate_options: nil,
            setup_future_usage: nil,
            target_date: nil,
            verification_method: nil
          )
            @currency = currency
            @mandate_options = mandate_options
            @setup_future_usage = setup_future_usage
            @target_date = target_date
            @verification_method = verification_method
          end
        end

        class Affirm < ::Stripe::RequestParams
          # Controls when the funds will be captured from the customer's account.
          attr_accessor :capture_method
          # Indicates that you intend to make future payments with this PaymentIntent's payment method.
          #
          # If you provide a Customer with the PaymentIntent, you can use this parameter to [attach the payment method](/payments/save-during-payment) to the Customer after the PaymentIntent is confirmed and the customer completes any required actions. If you don't provide a Customer, you can still [attach](/api/payment_methods/attach) the payment method to a Customer after the transaction completes.
          #
          # If the payment method is `card_present` and isn't a digital wallet, Stripe creates and attaches a [generated_card](/api/charges/object#charge_object-payment_method_details-card_present-generated_card) payment method representing the card to the Customer instead.
          #
          # When processing card payments, Stripe uses `setup_future_usage` to help you comply with regional legislation and network rules, such as [SCA](/strong-customer-authentication).
          attr_accessor :setup_future_usage

          def initialize(capture_method: nil, setup_future_usage: nil)
            @capture_method = capture_method
            @setup_future_usage = setup_future_usage
          end
        end

        class AfterpayClearpay < ::Stripe::RequestParams
          # Controls when the funds will be captured from the customer's account.
          attr_accessor :capture_method
          # Indicates that you intend to make future payments with this PaymentIntent's payment method.
          #
          # If you provide a Customer with the PaymentIntent, you can use this parameter to [attach the payment method](/payments/save-during-payment) to the Customer after the PaymentIntent is confirmed and the customer completes any required actions. If you don't provide a Customer, you can still [attach](/api/payment_methods/attach) the payment method to a Customer after the transaction completes.
          #
          # If the payment method is `card_present` and isn't a digital wallet, Stripe creates and attaches a [generated_card](/api/charges/object#charge_object-payment_method_details-card_present-generated_card) payment method representing the card to the Customer instead.
          #
          # When processing card payments, Stripe uses `setup_future_usage` to help you comply with regional legislation and network rules, such as [SCA](/strong-customer-authentication).
          attr_accessor :setup_future_usage

          def initialize(capture_method: nil, setup_future_usage: nil)
            @capture_method = capture_method
            @setup_future_usage = setup_future_usage
          end
        end

        class Alipay < ::Stripe::RequestParams
          # Indicates that you intend to make future payments with this PaymentIntent's payment method.
          #
          # If you provide a Customer with the PaymentIntent, you can use this parameter to [attach the payment method](/payments/save-during-payment) to the Customer after the PaymentIntent is confirmed and the customer completes any required actions. If you don't provide a Customer, you can still [attach](/api/payment_methods/attach) the payment method to a Customer after the transaction completes.
          #
          # If the payment method is `card_present` and isn't a digital wallet, Stripe creates and attaches a [generated_card](/api/charges/object#charge_object-payment_method_details-card_present-generated_card) payment method representing the card to the Customer instead.
          #
          # When processing card payments, Stripe uses `setup_future_usage` to help you comply with regional legislation and network rules, such as [SCA](/strong-customer-authentication).
          attr_accessor :setup_future_usage

          def initialize(setup_future_usage: nil)
            @setup_future_usage = setup_future_usage
          end
        end

        class Alma < ::Stripe::RequestParams
          # Controls when the funds will be captured from the customer's account.
          attr_accessor :capture_method

          def initialize(capture_method: nil)
            @capture_method = capture_method
          end
        end

        class AmazonPay < ::Stripe::RequestParams
          # Controls when the funds will be captured from the customer's account.
          attr_accessor :capture_method
          # Indicates that you intend to make future payments with this PaymentIntent's payment method.
          #
          # If you provide a Customer with the PaymentIntent, you can use this parameter to [attach the payment method](/payments/save-during-payment) to the Customer after the PaymentIntent is confirmed and the customer completes any required actions. If you don't provide a Customer, you can still [attach](/api/payment_methods/attach) the payment method to a Customer after the transaction completes.
          #
          # If the payment method is `card_present` and isn't a digital wallet, Stripe creates and attaches a [generated_card](/api/charges/object#charge_object-payment_method_details-card_present-generated_card) payment method representing the card to the Customer instead.
          #
          # When processing card payments, Stripe uses `setup_future_usage` to help you comply with regional legislation and network rules, such as [SCA](/strong-customer-authentication).
          attr_accessor :setup_future_usage

          def initialize(capture_method: nil, setup_future_usage: nil)
            @capture_method = capture_method
            @setup_future_usage = setup_future_usage
          end
        end

        class AuBecsDebit < ::Stripe::RequestParams
          # Indicates that you intend to make future payments with this PaymentIntent's payment method.
          #
          # If you provide a Customer with the PaymentIntent, you can use this parameter to [attach the payment method](/payments/save-during-payment) to the Customer after the PaymentIntent is confirmed and the customer completes any required actions. If you don't provide a Customer, you can still [attach](/api/payment_methods/attach) the payment method to a Customer after the transaction completes.
          #
          # If the payment method is `card_present` and isn't a digital wallet, Stripe creates and attaches a [generated_card](/api/charges/object#charge_object-payment_method_details-card_present-generated_card) payment method representing the card to the Customer instead.
          #
          # When processing card payments, Stripe uses `setup_future_usage` to help you comply with regional legislation and network rules, such as [SCA](/strong-customer-authentication).
          attr_accessor :setup_future_usage
          # Controls when Stripe will attempt to debit the funds from the customer's account. The date must be a string in YYYY-MM-DD format. The date must be in the future and between 3 and 15 calendar days from now.
          attr_accessor :target_date

          def initialize(setup_future_usage: nil, target_date: nil)
            @setup_future_usage = setup_future_usage
            @target_date = target_date
          end
        end

        class BacsDebit < ::Stripe::RequestParams
          class MandateOptions < ::Stripe::RequestParams
            # Prefix used to generate the Mandate reference. Must be at most 12 characters long. Must consist of only uppercase letters, numbers, spaces, or the following special characters: '/', '_', '-', '&', '.'. Cannot begin with 'DDIC' or 'STRIPE'.
            attr_accessor :reference_prefix

            def initialize(reference_prefix: nil)
              @reference_prefix = reference_prefix
            end
          end
          # Additional fields for Mandate creation
          attr_accessor :mandate_options
          # Indicates that you intend to make future payments with this PaymentIntent's payment method.
          #
          # If you provide a Customer with the PaymentIntent, you can use this parameter to [attach the payment method](/payments/save-during-payment) to the Customer after the PaymentIntent is confirmed and the customer completes any required actions. If you don't provide a Customer, you can still [attach](/api/payment_methods/attach) the payment method to a Customer after the transaction completes.
          #
          # If the payment method is `card_present` and isn't a digital wallet, Stripe creates and attaches a [generated_card](/api/charges/object#charge_object-payment_method_details-card_present-generated_card) payment method representing the card to the Customer instead.
          #
          # When processing card payments, Stripe uses `setup_future_usage` to help you comply with regional legislation and network rules, such as [SCA](/strong-customer-authentication).
          attr_accessor :setup_future_usage
          # Controls when Stripe will attempt to debit the funds from the customer's account. The date must be a string in YYYY-MM-DD format. The date must be in the future and between 3 and 15 calendar days from now.
          attr_accessor :target_date

          def initialize(mandate_options: nil, setup_future_usage: nil, target_date: nil)
            @mandate_options = mandate_options
            @setup_future_usage = setup_future_usage
            @target_date = target_date
          end
        end

        class Bancontact < ::Stripe::RequestParams
          # Indicates that you intend to make future payments with this PaymentIntent's payment method.
          #
          # If you provide a Customer with the PaymentIntent, you can use this parameter to [attach the payment method](/payments/save-during-payment) to the Customer after the PaymentIntent is confirmed and the customer completes any required actions. If you don't provide a Customer, you can still [attach](/api/payment_methods/attach) the payment method to a Customer after the transaction completes.
          #
          # If the payment method is `card_present` and isn't a digital wallet, Stripe creates and attaches a [generated_card](/api/charges/object#charge_object-payment_method_details-card_present-generated_card) payment method representing the card to the Customer instead.
          #
          # When processing card payments, Stripe uses `setup_future_usage` to help you comply with regional legislation and network rules, such as [SCA](/strong-customer-authentication).
          attr_accessor :setup_future_usage

          def initialize(setup_future_usage: nil)
            @setup_future_usage = setup_future_usage
          end
        end

        class Billie < ::Stripe::RequestParams
          # Controls when the funds will be captured from the customer's account.
          attr_accessor :capture_method

          def initialize(capture_method: nil)
            @capture_method = capture_method
          end
        end

        class Boleto < ::Stripe::RequestParams
          # The number of calendar days before a Boleto voucher expires. For example, if you create a Boleto voucher on Monday and you set expires_after_days to 2, the Boleto invoice will expire on Wednesday at 23:59 America/Sao_Paulo time.
          attr_accessor :expires_after_days
          # Indicates that you intend to make future payments with this PaymentIntent's payment method.
          #
          # If you provide a Customer with the PaymentIntent, you can use this parameter to [attach the payment method](/payments/save-during-payment) to the Customer after the PaymentIntent is confirmed and the customer completes any required actions. If you don't provide a Customer, you can still [attach](/api/payment_methods/attach) the payment method to a Customer after the transaction completes.
          #
          # If the payment method is `card_present` and isn't a digital wallet, Stripe creates and attaches a [generated_card](/api/charges/object#charge_object-payment_method_details-card_present-generated_card) payment method representing the card to the Customer instead.
          #
          # When processing card payments, Stripe uses `setup_future_usage` to help you comply with regional legislation and network rules, such as [SCA](/strong-customer-authentication).
          attr_accessor :setup_future_usage

          def initialize(expires_after_days: nil, setup_future_usage: nil)
            @expires_after_days = expires_after_days
            @setup_future_usage = setup_future_usage
          end
        end

        class Card < ::Stripe::RequestParams
          class Installments < ::Stripe::RequestParams
            # Setting to true enables installments for this Checkout Session.
            # Setting to false will prevent any installment plan from applying to a payment.
            attr_accessor :enabled

            def initialize(enabled: nil)
              @enabled = enabled
            end
          end

          class Restrictions < ::Stripe::RequestParams
            # Specify the card brands to block in the Checkout Session. If a customer enters or selects a card belonging to a blocked brand, they can't complete the Session.
            attr_accessor :brands_blocked

            def initialize(brands_blocked: nil)
              @brands_blocked = brands_blocked
            end
          end
          # Controls when the funds will be captured from the customer's account.
          attr_accessor :capture_method
          # Installment options for card payments
          attr_accessor :installments
          # Request ability to [capture beyond the standard authorization validity window](/payments/extended-authorization) for this CheckoutSession.
          attr_accessor :request_extended_authorization
          # Request ability to [increment the authorization](/payments/incremental-authorization) for this CheckoutSession.
          attr_accessor :request_incremental_authorization
          # Request ability to make [multiple captures](/payments/multicapture) for this CheckoutSession.
          attr_accessor :request_multicapture
          # Request ability to [overcapture](/payments/overcapture) for this CheckoutSession.
          attr_accessor :request_overcapture
          # We strongly recommend that you rely on our SCA Engine to automatically prompt your customers for authentication based on risk level and [other requirements](https://stripe.com/docs/strong-customer-authentication). However, if you wish to request 3D Secure based on logic from your own fraud engine, provide this option. If not provided, this value defaults to `automatic`. Read our guide on [manually requesting 3D Secure](https://stripe.com/docs/payments/3d-secure/authentication-flow#manual-three-ds) for more information on how this configuration interacts with Radar and our SCA Engine.
          attr_accessor :request_three_d_secure
          # Restrictions to apply to the card payment method. For example, you can block specific card brands.
          attr_accessor :restrictions
          # Indicates that you intend to make future payments with this PaymentIntent's payment method.
          #
          # If you provide a Customer with the PaymentIntent, you can use this parameter to [attach the payment method](/payments/save-during-payment) to the Customer after the PaymentIntent is confirmed and the customer completes any required actions. If you don't provide a Customer, you can still [attach](/api/payment_methods/attach) the payment method to a Customer after the transaction completes.
          #
          # If the payment method is `card_present` and isn't a digital wallet, Stripe creates and attaches a [generated_card](/api/charges/object#charge_object-payment_method_details-card_present-generated_card) payment method representing the card to the Customer instead.
          #
          # When processing card payments, Stripe uses `setup_future_usage` to help you comply with regional legislation and network rules, such as [SCA](/strong-customer-authentication).
          attr_accessor :setup_future_usage
          # Provides information about a card payment that customers see on their statements. Concatenated with the Kana prefix (shortened Kana descriptor) or Kana statement descriptor that’s set on the account to form the complete statement descriptor. Maximum 22 characters. On card statements, the *concatenation* of both prefix and suffix (including separators) will appear truncated to 22 characters.
          attr_accessor :statement_descriptor_suffix_kana
          # Provides information about a card payment that customers see on their statements. Concatenated with the Kanji prefix (shortened Kanji descriptor) or Kanji statement descriptor that’s set on the account to form the complete statement descriptor. Maximum 17 characters. On card statements, the *concatenation* of both prefix and suffix (including separators) will appear truncated to 17 characters.
          attr_accessor :statement_descriptor_suffix_kanji

          def initialize(
            capture_method: nil,
            installments: nil,
            request_extended_authorization: nil,
            request_incremental_authorization: nil,
            request_multicapture: nil,
            request_overcapture: nil,
            request_three_d_secure: nil,
            restrictions: nil,
            setup_future_usage: nil,
            statement_descriptor_suffix_kana: nil,
            statement_descriptor_suffix_kanji: nil
          )
            @capture_method = capture_method
            @installments = installments
            @request_extended_authorization = request_extended_authorization
            @request_incremental_authorization = request_incremental_authorization
            @request_multicapture = request_multicapture
            @request_overcapture = request_overcapture
            @request_three_d_secure = request_three_d_secure
            @restrictions = restrictions
            @setup_future_usage = setup_future_usage
            @statement_descriptor_suffix_kana = statement_descriptor_suffix_kana
            @statement_descriptor_suffix_kanji = statement_descriptor_suffix_kanji
          end
        end

        class Cashapp < ::Stripe::RequestParams
          # Controls when the funds will be captured from the customer's account.
          attr_accessor :capture_method
          # Indicates that you intend to make future payments with this PaymentIntent's payment method.
          #
          # If you provide a Customer with the PaymentIntent, you can use this parameter to [attach the payment method](/payments/save-during-payment) to the Customer after the PaymentIntent is confirmed and the customer completes any required actions. If you don't provide a Customer, you can still [attach](/api/payment_methods/attach) the payment method to a Customer after the transaction completes.
          #
          # If the payment method is `card_present` and isn't a digital wallet, Stripe creates and attaches a [generated_card](/api/charges/object#charge_object-payment_method_details-card_present-generated_card) payment method representing the card to the Customer instead.
          #
          # When processing card payments, Stripe uses `setup_future_usage` to help you comply with regional legislation and network rules, such as [SCA](/strong-customer-authentication).
          attr_accessor :setup_future_usage

          def initialize(capture_method: nil, setup_future_usage: nil)
            @capture_method = capture_method
            @setup_future_usage = setup_future_usage
          end
        end

        class CustomerBalance < ::Stripe::RequestParams
          class BankTransfer < ::Stripe::RequestParams
            class EuBankTransfer < ::Stripe::RequestParams
              # The desired country code of the bank account information. Permitted values include: `BE`, `DE`, `ES`, `FR`, `IE`, or `NL`.
              attr_accessor :country

              def initialize(country: nil)
                @country = country
              end
            end
            # Configuration for eu_bank_transfer funding type.
            attr_accessor :eu_bank_transfer
            # List of address types that should be returned in the financial_addresses response. If not specified, all valid types will be returned.
            #
            # Permitted values include: `sort_code`, `zengin`, `iban`, or `spei`.
            attr_accessor :requested_address_types
            # The list of bank transfer types that this PaymentIntent is allowed to use for funding.
            attr_accessor :type

            def initialize(eu_bank_transfer: nil, requested_address_types: nil, type: nil)
              @eu_bank_transfer = eu_bank_transfer
              @requested_address_types = requested_address_types
              @type = type
            end
          end
          # Configuration for the bank transfer funding type, if the `funding_type` is set to `bank_transfer`.
          attr_accessor :bank_transfer
          # The funding method type to be used when there are not enough funds in the customer balance. Permitted values include: `bank_transfer`.
          attr_accessor :funding_type
          # Indicates that you intend to make future payments with this PaymentIntent's payment method.
          #
          # If you provide a Customer with the PaymentIntent, you can use this parameter to [attach the payment method](/payments/save-during-payment) to the Customer after the PaymentIntent is confirmed and the customer completes any required actions. If you don't provide a Customer, you can still [attach](/api/payment_methods/attach) the payment method to a Customer after the transaction completes.
          #
          # If the payment method is `card_present` and isn't a digital wallet, Stripe creates and attaches a [generated_card](/api/charges/object#charge_object-payment_method_details-card_present-generated_card) payment method representing the card to the Customer instead.
          #
          # When processing card payments, Stripe uses `setup_future_usage` to help you comply with regional legislation and network rules, such as [SCA](/strong-customer-authentication).
          attr_accessor :setup_future_usage

          def initialize(bank_transfer: nil, funding_type: nil, setup_future_usage: nil)
            @bank_transfer = bank_transfer
            @funding_type = funding_type
            @setup_future_usage = setup_future_usage
          end
        end

        class DemoPay < ::Stripe::RequestParams
          # Indicates that you intend to make future payments with this PaymentIntent's payment method.
          #
          # If you provide a Customer with the PaymentIntent, you can use this parameter to [attach the payment method](/payments/save-during-payment) to the Customer after the PaymentIntent is confirmed and the customer completes any required actions. If you don't provide a Customer, you can still [attach](/api/payment_methods/attach) the payment method to a Customer after the transaction completes.
          #
          # If the payment method is `card_present` and isn't a digital wallet, Stripe creates and attaches a [generated_card](/api/charges/object#charge_object-payment_method_details-card_present-generated_card) payment method representing the card to the Customer instead.
          #
          # When processing card payments, Stripe uses `setup_future_usage` to help you comply with regional legislation and network rules, such as [SCA](/strong-customer-authentication).
          attr_accessor :setup_future_usage

          def initialize(setup_future_usage: nil)
            @setup_future_usage = setup_future_usage
          end
        end

        class Eps < ::Stripe::RequestParams
          # Indicates that you intend to make future payments with this PaymentIntent's payment method.
          #
          # If you provide a Customer with the PaymentIntent, you can use this parameter to [attach the payment method](/payments/save-during-payment) to the Customer after the PaymentIntent is confirmed and the customer completes any required actions. If you don't provide a Customer, you can still [attach](/api/payment_methods/attach) the payment method to a Customer after the transaction completes.
          #
          # If the payment method is `card_present` and isn't a digital wallet, Stripe creates and attaches a [generated_card](/api/charges/object#charge_object-payment_method_details-card_present-generated_card) payment method representing the card to the Customer instead.
          #
          # When processing card payments, Stripe uses `setup_future_usage` to help you comply with regional legislation and network rules, such as [SCA](/strong-customer-authentication).
          attr_accessor :setup_future_usage

          def initialize(setup_future_usage: nil)
            @setup_future_usage = setup_future_usage
          end
        end

        class Fpx < ::Stripe::RequestParams
          # Indicates that you intend to make future payments with this PaymentIntent's payment method.
          #
          # If you provide a Customer with the PaymentIntent, you can use this parameter to [attach the payment method](/payments/save-during-payment) to the Customer after the PaymentIntent is confirmed and the customer completes any required actions. If you don't provide a Customer, you can still [attach](/api/payment_methods/attach) the payment method to a Customer after the transaction completes.
          #
          # If the payment method is `card_present` and isn't a digital wallet, Stripe creates and attaches a [generated_card](/api/charges/object#charge_object-payment_method_details-card_present-generated_card) payment method representing the card to the Customer instead.
          #
          # When processing card payments, Stripe uses `setup_future_usage` to help you comply with regional legislation and network rules, such as [SCA](/strong-customer-authentication).
          attr_accessor :setup_future_usage

          def initialize(setup_future_usage: nil)
            @setup_future_usage = setup_future_usage
          end
        end

        class Giropay < ::Stripe::RequestParams
          # Indicates that you intend to make future payments with this PaymentIntent's payment method.
          #
          # If you provide a Customer with the PaymentIntent, you can use this parameter to [attach the payment method](/payments/save-during-payment) to the Customer after the PaymentIntent is confirmed and the customer completes any required actions. If you don't provide a Customer, you can still [attach](/api/payment_methods/attach) the payment method to a Customer after the transaction completes.
          #
          # If the payment method is `card_present` and isn't a digital wallet, Stripe creates and attaches a [generated_card](/api/charges/object#charge_object-payment_method_details-card_present-generated_card) payment method representing the card to the Customer instead.
          #
          # When processing card payments, Stripe uses `setup_future_usage` to help you comply with regional legislation and network rules, such as [SCA](/strong-customer-authentication).
          attr_accessor :setup_future_usage

          def initialize(setup_future_usage: nil)
            @setup_future_usage = setup_future_usage
          end
        end

        class Grabpay < ::Stripe::RequestParams
          # Indicates that you intend to make future payments with this PaymentIntent's payment method.
          #
          # If you provide a Customer with the PaymentIntent, you can use this parameter to [attach the payment method](/payments/save-during-payment) to the Customer after the PaymentIntent is confirmed and the customer completes any required actions. If you don't provide a Customer, you can still [attach](/api/payment_methods/attach) the payment method to a Customer after the transaction completes.
          #
          # If the payment method is `card_present` and isn't a digital wallet, Stripe creates and attaches a [generated_card](/api/charges/object#charge_object-payment_method_details-card_present-generated_card) payment method representing the card to the Customer instead.
          #
          # When processing card payments, Stripe uses `setup_future_usage` to help you comply with regional legislation and network rules, such as [SCA](/strong-customer-authentication).
          attr_accessor :setup_future_usage

          def initialize(setup_future_usage: nil)
            @setup_future_usage = setup_future_usage
          end
        end

        class Ideal < ::Stripe::RequestParams
          # Indicates that you intend to make future payments with this PaymentIntent's payment method.
          #
          # If you provide a Customer with the PaymentIntent, you can use this parameter to [attach the payment method](/payments/save-during-payment) to the Customer after the PaymentIntent is confirmed and the customer completes any required actions. If you don't provide a Customer, you can still [attach](/api/payment_methods/attach) the payment method to a Customer after the transaction completes.
          #
          # If the payment method is `card_present` and isn't a digital wallet, Stripe creates and attaches a [generated_card](/api/charges/object#charge_object-payment_method_details-card_present-generated_card) payment method representing the card to the Customer instead.
          #
          # When processing card payments, Stripe uses `setup_future_usage` to help you comply with regional legislation and network rules, such as [SCA](/strong-customer-authentication).
          attr_accessor :setup_future_usage

          def initialize(setup_future_usage: nil)
            @setup_future_usage = setup_future_usage
          end
        end

        class KakaoPay < ::Stripe::RequestParams
          # Controls when the funds will be captured from the customer's account.
          attr_accessor :capture_method
          # Indicates that you intend to make future payments with this PaymentIntent's payment method.
          #
          # If you provide a Customer with the PaymentIntent, you can use this parameter to [attach the payment method](/payments/save-during-payment) to the Customer after the PaymentIntent is confirmed and the customer completes any required actions. If you don't provide a Customer, you can still [attach](/api/payment_methods/attach) the payment method to a Customer after the transaction completes.
          #
          # If the payment method is `card_present` and isn't a digital wallet, Stripe creates and attaches a [generated_card](/api/charges/object#charge_object-payment_method_details-card_present-generated_card) payment method representing the card to the Customer instead.
          #
          # When processing card payments, Stripe uses `setup_future_usage` to help you comply with regional legislation and network rules, such as [SCA](/strong-customer-authentication).
          attr_accessor :setup_future_usage

          def initialize(capture_method: nil, setup_future_usage: nil)
            @capture_method = capture_method
            @setup_future_usage = setup_future_usage
          end
        end

        class Klarna < ::Stripe::RequestParams
          class Subscription < ::Stripe::RequestParams
            class NextBilling < ::Stripe::RequestParams
              # The amount of the next charge for the subscription.
              attr_accessor :amount
              # The date of the next charge for the subscription in YYYY-MM-DD format.
              attr_accessor :date

              def initialize(amount: nil, date: nil)
                @amount = amount
                @date = date
              end
            end
            # Unit of time between subscription charges.
            attr_accessor :interval
            # The number of intervals (specified in the `interval` attribute) between subscription charges. For example, `interval=month` and `interval_count=3` charges every 3 months.
            attr_accessor :interval_count
            # Name for subscription.
            attr_accessor :name
            # Describes the upcoming charge for this subscription.
            attr_accessor :next_billing
            # A non-customer-facing reference to correlate subscription charges in the Klarna app. Use a value that persists across subscription charges.
            attr_accessor :reference

            def initialize(
              interval: nil,
              interval_count: nil,
              name: nil,
              next_billing: nil,
              reference: nil
            )
              @interval = interval
              @interval_count = interval_count
              @name = name
              @next_billing = next_billing
              @reference = reference
            end
          end
          # Controls when the funds will be captured from the customer's account.
          attr_accessor :capture_method
          # Indicates that you intend to make future payments with this PaymentIntent's payment method.
          #
          # If you provide a Customer with the PaymentIntent, you can use this parameter to [attach the payment method](/payments/save-during-payment) to the Customer after the PaymentIntent is confirmed and the customer completes any required actions. If you don't provide a Customer, you can still [attach](/api/payment_methods/attach) the payment method to a Customer after the transaction completes.
          #
          # If the payment method is `card_present` and isn't a digital wallet, Stripe creates and attaches a [generated_card](/api/charges/object#charge_object-payment_method_details-card_present-generated_card) payment method representing the card to the Customer instead.
          #
          # When processing card payments, Stripe uses `setup_future_usage` to help you comply with regional legislation and network rules, such as [SCA](/strong-customer-authentication).
          attr_accessor :setup_future_usage
          # Subscription details if the Checkout Session sets up a future subscription.
          attr_accessor :subscriptions

          def initialize(capture_method: nil, setup_future_usage: nil, subscriptions: nil)
            @capture_method = capture_method
            @setup_future_usage = setup_future_usage
            @subscriptions = subscriptions
          end
        end

        class Konbini < ::Stripe::RequestParams
          # The number of calendar days (between 1 and 60) after which Konbini payment instructions will expire. For example, if a PaymentIntent is confirmed with Konbini and `expires_after_days` set to 2 on Monday JST, the instructions will expire on Wednesday 23:59:59 JST. Defaults to 3 days.
          attr_accessor :expires_after_days
          # Indicates that you intend to make future payments with this PaymentIntent's payment method.
          #
          # If you provide a Customer with the PaymentIntent, you can use this parameter to [attach the payment method](/payments/save-during-payment) to the Customer after the PaymentIntent is confirmed and the customer completes any required actions. If you don't provide a Customer, you can still [attach](/api/payment_methods/attach) the payment method to a Customer after the transaction completes.
          #
          # If the payment method is `card_present` and isn't a digital wallet, Stripe creates and attaches a [generated_card](/api/charges/object#charge_object-payment_method_details-card_present-generated_card) payment method representing the card to the Customer instead.
          #
          # When processing card payments, Stripe uses `setup_future_usage` to help you comply with regional legislation and network rules, such as [SCA](/strong-customer-authentication).
          attr_accessor :setup_future_usage

          def initialize(expires_after_days: nil, setup_future_usage: nil)
            @expires_after_days = expires_after_days
            @setup_future_usage = setup_future_usage
          end
        end

        class KrCard < ::Stripe::RequestParams
          # Controls when the funds will be captured from the customer's account.
          attr_accessor :capture_method
          # Indicates that you intend to make future payments with this PaymentIntent's payment method.
          #
          # If you provide a Customer with the PaymentIntent, you can use this parameter to [attach the payment method](/payments/save-during-payment) to the Customer after the PaymentIntent is confirmed and the customer completes any required actions. If you don't provide a Customer, you can still [attach](/api/payment_methods/attach) the payment method to a Customer after the transaction completes.
          #
          # If the payment method is `card_present` and isn't a digital wallet, Stripe creates and attaches a [generated_card](/api/charges/object#charge_object-payment_method_details-card_present-generated_card) payment method representing the card to the Customer instead.
          #
          # When processing card payments, Stripe uses `setup_future_usage` to help you comply with regional legislation and network rules, such as [SCA](/strong-customer-authentication).
          attr_accessor :setup_future_usage

          def initialize(capture_method: nil, setup_future_usage: nil)
            @capture_method = capture_method
            @setup_future_usage = setup_future_usage
          end
        end

        class Link < ::Stripe::RequestParams
          # Controls when the funds will be captured from the customer's account.
          attr_accessor :capture_method
          # Indicates that you intend to make future payments with this PaymentIntent's payment method.
          #
          # If you provide a Customer with the PaymentIntent, you can use this parameter to [attach the payment method](/payments/save-during-payment) to the Customer after the PaymentIntent is confirmed and the customer completes any required actions. If you don't provide a Customer, you can still [attach](/api/payment_methods/attach) the payment method to a Customer after the transaction completes.
          #
          # If the payment method is `card_present` and isn't a digital wallet, Stripe creates and attaches a [generated_card](/api/charges/object#charge_object-payment_method_details-card_present-generated_card) payment method representing the card to the Customer instead.
          #
          # When processing card payments, Stripe uses `setup_future_usage` to help you comply with regional legislation and network rules, such as [SCA](/strong-customer-authentication).
          attr_accessor :setup_future_usage

          def initialize(capture_method: nil, setup_future_usage: nil)
            @capture_method = capture_method
            @setup_future_usage = setup_future_usage
          end
        end

        class Mobilepay < ::Stripe::RequestParams
          # Controls when the funds will be captured from the customer's account.
          attr_accessor :capture_method
          # Indicates that you intend to make future payments with this PaymentIntent's payment method.
          #
          # If you provide a Customer with the PaymentIntent, you can use this parameter to [attach the payment method](/payments/save-during-payment) to the Customer after the PaymentIntent is confirmed and the customer completes any required actions. If you don't provide a Customer, you can still [attach](/api/payment_methods/attach) the payment method to a Customer after the transaction completes.
          #
          # If the payment method is `card_present` and isn't a digital wallet, Stripe creates and attaches a [generated_card](/api/charges/object#charge_object-payment_method_details-card_present-generated_card) payment method representing the card to the Customer instead.
          #
          # When processing card payments, Stripe uses `setup_future_usage` to help you comply with regional legislation and network rules, such as [SCA](/strong-customer-authentication).
          attr_accessor :setup_future_usage

          def initialize(capture_method: nil, setup_future_usage: nil)
            @capture_method = capture_method
            @setup_future_usage = setup_future_usage
          end
        end

        class Multibanco < ::Stripe::RequestParams
          # Indicates that you intend to make future payments with this PaymentIntent's payment method.
          #
          # If you provide a Customer with the PaymentIntent, you can use this parameter to [attach the payment method](/payments/save-during-payment) to the Customer after the PaymentIntent is confirmed and the customer completes any required actions. If you don't provide a Customer, you can still [attach](/api/payment_methods/attach) the payment method to a Customer after the transaction completes.
          #
          # If the payment method is `card_present` and isn't a digital wallet, Stripe creates and attaches a [generated_card](/api/charges/object#charge_object-payment_method_details-card_present-generated_card) payment method representing the card to the Customer instead.
          #
          # When processing card payments, Stripe uses `setup_future_usage` to help you comply with regional legislation and network rules, such as [SCA](/strong-customer-authentication).
          attr_accessor :setup_future_usage

          def initialize(setup_future_usage: nil)
            @setup_future_usage = setup_future_usage
          end
        end

        class NaverPay < ::Stripe::RequestParams
          # Controls when the funds will be captured from the customer's account.
          attr_accessor :capture_method
          # Indicates that you intend to make future payments with this PaymentIntent's payment method.
          #
          # If you provide a Customer with the PaymentIntent, you can use this parameter to [attach the payment method](/payments/save-during-payment) to the Customer after the PaymentIntent is confirmed and the customer completes any required actions. If you don't provide a Customer, you can still [attach](/api/payment_methods/attach) the payment method to a Customer after the transaction completes.
          #
          # If the payment method is `card_present` and isn't a digital wallet, Stripe creates and attaches a [generated_card](/api/charges/object#charge_object-payment_method_details-card_present-generated_card) payment method representing the card to the Customer instead.
          #
          # When processing card payments, Stripe uses `setup_future_usage` to help you comply with regional legislation and network rules, such as [SCA](/strong-customer-authentication).
          attr_accessor :setup_future_usage

          def initialize(capture_method: nil, setup_future_usage: nil)
            @capture_method = capture_method
            @setup_future_usage = setup_future_usage
          end
        end

        class Oxxo < ::Stripe::RequestParams
          # The number of calendar days before an OXXO voucher expires. For example, if you create an OXXO voucher on Monday and you set expires_after_days to 2, the OXXO invoice will expire on Wednesday at 23:59 America/Mexico_City time.
          attr_accessor :expires_after_days
          # Indicates that you intend to make future payments with this PaymentIntent's payment method.
          #
          # If you provide a Customer with the PaymentIntent, you can use this parameter to [attach the payment method](/payments/save-during-payment) to the Customer after the PaymentIntent is confirmed and the customer completes any required actions. If you don't provide a Customer, you can still [attach](/api/payment_methods/attach) the payment method to a Customer after the transaction completes.
          #
          # If the payment method is `card_present` and isn't a digital wallet, Stripe creates and attaches a [generated_card](/api/charges/object#charge_object-payment_method_details-card_present-generated_card) payment method representing the card to the Customer instead.
          #
          # When processing card payments, Stripe uses `setup_future_usage` to help you comply with regional legislation and network rules, such as [SCA](/strong-customer-authentication).
          attr_accessor :setup_future_usage

          def initialize(expires_after_days: nil, setup_future_usage: nil)
            @expires_after_days = expires_after_days
            @setup_future_usage = setup_future_usage
          end
        end

        class P24 < ::Stripe::RequestParams
          # Indicates that you intend to make future payments with this PaymentIntent's payment method.
          #
          # If you provide a Customer with the PaymentIntent, you can use this parameter to [attach the payment method](/payments/save-during-payment) to the Customer after the PaymentIntent is confirmed and the customer completes any required actions. If you don't provide a Customer, you can still [attach](/api/payment_methods/attach) the payment method to a Customer after the transaction completes.
          #
          # If the payment method is `card_present` and isn't a digital wallet, Stripe creates and attaches a [generated_card](/api/charges/object#charge_object-payment_method_details-card_present-generated_card) payment method representing the card to the Customer instead.
          #
          # When processing card payments, Stripe uses `setup_future_usage` to help you comply with regional legislation and network rules, such as [SCA](/strong-customer-authentication).
          attr_accessor :setup_future_usage
          # Confirm that the payer has accepted the P24 terms and conditions.
          attr_accessor :tos_shown_and_accepted

          def initialize(setup_future_usage: nil, tos_shown_and_accepted: nil)
            @setup_future_usage = setup_future_usage
            @tos_shown_and_accepted = tos_shown_and_accepted
          end
        end

        class PayByBank < ::Stripe::RequestParams; end

        class Payco < ::Stripe::RequestParams
          # Controls when the funds will be captured from the customer's account.
          attr_accessor :capture_method

          def initialize(capture_method: nil)
            @capture_method = capture_method
          end
        end

        class Paynow < ::Stripe::RequestParams
          # Indicates that you intend to make future payments with this PaymentIntent's payment method.
          #
          # If you provide a Customer with the PaymentIntent, you can use this parameter to [attach the payment method](/payments/save-during-payment) to the Customer after the PaymentIntent is confirmed and the customer completes any required actions. If you don't provide a Customer, you can still [attach](/api/payment_methods/attach) the payment method to a Customer after the transaction completes.
          #
          # If the payment method is `card_present` and isn't a digital wallet, Stripe creates and attaches a [generated_card](/api/charges/object#charge_object-payment_method_details-card_present-generated_card) payment method representing the card to the Customer instead.
          #
          # When processing card payments, Stripe uses `setup_future_usage` to help you comply with regional legislation and network rules, such as [SCA](/strong-customer-authentication).
          attr_accessor :setup_future_usage

          def initialize(setup_future_usage: nil)
            @setup_future_usage = setup_future_usage
          end
        end

        class Paypal < ::Stripe::RequestParams
          # Controls when the funds will be captured from the customer's account.
          attr_accessor :capture_method
          # [Preferred locale](https://stripe.com/docs/payments/paypal/supported-locales) of the PayPal checkout page that the customer is redirected to.
          attr_accessor :preferred_locale
          # A reference of the PayPal transaction visible to customer which is mapped to PayPal's invoice ID. This must be a globally unique ID if you have configured in your PayPal settings to block multiple payments per invoice ID.
          attr_accessor :reference
          # The risk correlation ID for an on-session payment using a saved PayPal payment method.
          attr_accessor :risk_correlation_id
          # Indicates that you intend to make future payments with this PaymentIntent's payment method.
          #
          # If you provide a Customer with the PaymentIntent, you can use this parameter to [attach the payment method](/payments/save-during-payment) to the Customer after the PaymentIntent is confirmed and the customer completes any required actions. If you don't provide a Customer, you can still [attach](/api/payment_methods/attach) the payment method to a Customer after the transaction completes.
          #
          # If the payment method is `card_present` and isn't a digital wallet, Stripe creates and attaches a [generated_card](/api/charges/object#charge_object-payment_method_details-card_present-generated_card) payment method representing the card to the Customer instead.
          #
          # When processing card payments, Stripe uses `setup_future_usage` to help you comply with regional legislation and network rules, such as [SCA](/strong-customer-authentication).
          #
          # If you've already set `setup_future_usage` and you're performing a request using a publishable key, you can only update the value from `on_session` to `off_session`.
          attr_accessor :setup_future_usage

          def initialize(
            capture_method: nil,
            preferred_locale: nil,
            reference: nil,
            risk_correlation_id: nil,
            setup_future_usage: nil
          )
            @capture_method = capture_method
            @preferred_locale = preferred_locale
            @reference = reference
            @risk_correlation_id = risk_correlation_id
            @setup_future_usage = setup_future_usage
          end
        end

        class Pix < ::Stripe::RequestParams
          # Determines if the amount includes the IOF tax. Defaults to `never`.
          attr_accessor :amount_includes_iof
          # The number of seconds (between 10 and 1209600) after which Pix payment will expire. Defaults to 86400 seconds.
          attr_accessor :expires_after_seconds
          # Indicates that you intend to make future payments with this PaymentIntent's payment method.
          #
          # If you provide a Customer with the PaymentIntent, you can use this parameter to [attach the payment method](/payments/save-during-payment) to the Customer after the PaymentIntent is confirmed and the customer completes any required actions. If you don't provide a Customer, you can still [attach](/api/payment_methods/attach) the payment method to a Customer after the transaction completes.
          #
          # If the payment method is `card_present` and isn't a digital wallet, Stripe creates and attaches a [generated_card](/api/charges/object#charge_object-payment_method_details-card_present-generated_card) payment method representing the card to the Customer instead.
          #
          # When processing card payments, Stripe uses `setup_future_usage` to help you comply with regional legislation and network rules, such as [SCA](/strong-customer-authentication).
          attr_accessor :setup_future_usage

          def initialize(
            amount_includes_iof: nil,
            expires_after_seconds: nil,
            setup_future_usage: nil
          )
            @amount_includes_iof = amount_includes_iof
            @expires_after_seconds = expires_after_seconds
            @setup_future_usage = setup_future_usage
          end
        end

        class RevolutPay < ::Stripe::RequestParams
          # Controls when the funds will be captured from the customer's account.
          attr_accessor :capture_method
          # Indicates that you intend to make future payments with this PaymentIntent's payment method.
          #
          # If you provide a Customer with the PaymentIntent, you can use this parameter to [attach the payment method](/payments/save-during-payment) to the Customer after the PaymentIntent is confirmed and the customer completes any required actions. If you don't provide a Customer, you can still [attach](/api/payment_methods/attach) the payment method to a Customer after the transaction completes.
          #
          # If the payment method is `card_present` and isn't a digital wallet, Stripe creates and attaches a [generated_card](/api/charges/object#charge_object-payment_method_details-card_present-generated_card) payment method representing the card to the Customer instead.
          #
          # When processing card payments, Stripe uses `setup_future_usage` to help you comply with regional legislation and network rules, such as [SCA](/strong-customer-authentication).
          attr_accessor :setup_future_usage

          def initialize(capture_method: nil, setup_future_usage: nil)
            @capture_method = capture_method
            @setup_future_usage = setup_future_usage
          end
        end

        class SamsungPay < ::Stripe::RequestParams
          # Controls when the funds will be captured from the customer's account.
          attr_accessor :capture_method

          def initialize(capture_method: nil)
            @capture_method = capture_method
          end
        end

        class Satispay < ::Stripe::RequestParams
          # Controls when the funds will be captured from the customer's account.
          attr_accessor :capture_method

          def initialize(capture_method: nil)
            @capture_method = capture_method
          end
        end

        class SepaDebit < ::Stripe::RequestParams
          class MandateOptions < ::Stripe::RequestParams
            # Prefix used to generate the Mandate reference. Must be at most 12 characters long. Must consist of only uppercase letters, numbers, spaces, or the following special characters: '/', '_', '-', '&', '.'. Cannot begin with 'STRIPE'.
            attr_accessor :reference_prefix

            def initialize(reference_prefix: nil)
              @reference_prefix = reference_prefix
            end
          end
          # Additional fields for Mandate creation
          attr_accessor :mandate_options
          # Indicates that you intend to make future payments with this PaymentIntent's payment method.
          #
          # If you provide a Customer with the PaymentIntent, you can use this parameter to [attach the payment method](/payments/save-during-payment) to the Customer after the PaymentIntent is confirmed and the customer completes any required actions. If you don't provide a Customer, you can still [attach](/api/payment_methods/attach) the payment method to a Customer after the transaction completes.
          #
          # If the payment method is `card_present` and isn't a digital wallet, Stripe creates and attaches a [generated_card](/api/charges/object#charge_object-payment_method_details-card_present-generated_card) payment method representing the card to the Customer instead.
          #
          # When processing card payments, Stripe uses `setup_future_usage` to help you comply with regional legislation and network rules, such as [SCA](/strong-customer-authentication).
          attr_accessor :setup_future_usage
          # Controls when Stripe will attempt to debit the funds from the customer's account. The date must be a string in YYYY-MM-DD format. The date must be in the future and between 3 and 15 calendar days from now.
          attr_accessor :target_date

          def initialize(mandate_options: nil, setup_future_usage: nil, target_date: nil)
            @mandate_options = mandate_options
            @setup_future_usage = setup_future_usage
            @target_date = target_date
          end
        end

        class Sofort < ::Stripe::RequestParams
          # Indicates that you intend to make future payments with this PaymentIntent's payment method.
          #
          # If you provide a Customer with the PaymentIntent, you can use this parameter to [attach the payment method](/payments/save-during-payment) to the Customer after the PaymentIntent is confirmed and the customer completes any required actions. If you don't provide a Customer, you can still [attach](/api/payment_methods/attach) the payment method to a Customer after the transaction completes.
          #
          # If the payment method is `card_present` and isn't a digital wallet, Stripe creates and attaches a [generated_card](/api/charges/object#charge_object-payment_method_details-card_present-generated_card) payment method representing the card to the Customer instead.
          #
          # When processing card payments, Stripe uses `setup_future_usage` to help you comply with regional legislation and network rules, such as [SCA](/strong-customer-authentication).
          attr_accessor :setup_future_usage

          def initialize(setup_future_usage: nil)
            @setup_future_usage = setup_future_usage
          end
        end

        class Swish < ::Stripe::RequestParams
          # The order reference that will be displayed to customers in the Swish application. Defaults to the `id` of the Payment Intent.
          attr_accessor :reference

          def initialize(reference: nil)
            @reference = reference
          end
        end

        class Twint < ::Stripe::RequestParams
          # Indicates that you intend to make future payments with this PaymentIntent's payment method.
          #
          # If you provide a Customer with the PaymentIntent, you can use this parameter to [attach the payment method](/payments/save-during-payment) to the Customer after the PaymentIntent is confirmed and the customer completes any required actions. If you don't provide a Customer, you can still [attach](/api/payment_methods/attach) the payment method to a Customer after the transaction completes.
          #
          # If the payment method is `card_present` and isn't a digital wallet, Stripe creates and attaches a [generated_card](/api/charges/object#charge_object-payment_method_details-card_present-generated_card) payment method representing the card to the Customer instead.
          #
          # When processing card payments, Stripe uses `setup_future_usage` to help you comply with regional legislation and network rules, such as [SCA](/strong-customer-authentication).
          attr_accessor :setup_future_usage

          def initialize(setup_future_usage: nil)
            @setup_future_usage = setup_future_usage
          end
        end

        class UsBankAccount < ::Stripe::RequestParams
          class FinancialConnections < ::Stripe::RequestParams
            # The list of permissions to request. If this parameter is passed, the `payment_method` permission must be included. Valid permissions include: `balances`, `ownership`, `payment_method`, and `transactions`.
            attr_accessor :permissions
            # List of data features that you would like to retrieve upon account creation.
            attr_accessor :prefetch

            def initialize(permissions: nil, prefetch: nil)
              @permissions = permissions
              @prefetch = prefetch
            end
          end
          # Additional fields for Financial Connections Session creation
          attr_accessor :financial_connections
          # Indicates that you intend to make future payments with this PaymentIntent's payment method.
          #
          # If you provide a Customer with the PaymentIntent, you can use this parameter to [attach the payment method](/payments/save-during-payment) to the Customer after the PaymentIntent is confirmed and the customer completes any required actions. If you don't provide a Customer, you can still [attach](/api/payment_methods/attach) the payment method to a Customer after the transaction completes.
          #
          # If the payment method is `card_present` and isn't a digital wallet, Stripe creates and attaches a [generated_card](/api/charges/object#charge_object-payment_method_details-card_present-generated_card) payment method representing the card to the Customer instead.
          #
          # When processing card payments, Stripe uses `setup_future_usage` to help you comply with regional legislation and network rules, such as [SCA](/strong-customer-authentication).
          attr_accessor :setup_future_usage
          # Controls when Stripe will attempt to debit the funds from the customer's account. The date must be a string in YYYY-MM-DD format. The date must be in the future and between 3 and 15 calendar days from now.
          attr_accessor :target_date
          # Verification method for the intent
          attr_accessor :verification_method

          def initialize(
            financial_connections: nil,
            setup_future_usage: nil,
            target_date: nil,
            verification_method: nil
          )
            @financial_connections = financial_connections
            @setup_future_usage = setup_future_usage
            @target_date = target_date
            @verification_method = verification_method
          end
        end

        class WechatPay < ::Stripe::RequestParams
          # The app ID registered with WeChat Pay. Only required when client is ios or android.
          attr_accessor :app_id
          # The client type that the end customer will pay from
          attr_accessor :client
          # Indicates that you intend to make future payments with this PaymentIntent's payment method.
          #
          # If you provide a Customer with the PaymentIntent, you can use this parameter to [attach the payment method](/payments/save-during-payment) to the Customer after the PaymentIntent is confirmed and the customer completes any required actions. If you don't provide a Customer, you can still [attach](/api/payment_methods/attach) the payment method to a Customer after the transaction completes.
          #
          # If the payment method is `card_present` and isn't a digital wallet, Stripe creates and attaches a [generated_card](/api/charges/object#charge_object-payment_method_details-card_present-generated_card) payment method representing the card to the Customer instead.
          #
          # When processing card payments, Stripe uses `setup_future_usage` to help you comply with regional legislation and network rules, such as [SCA](/strong-customer-authentication).
          attr_accessor :setup_future_usage

          def initialize(app_id: nil, client: nil, setup_future_usage: nil)
            @app_id = app_id
            @client = client
            @setup_future_usage = setup_future_usage
          end
        end
        # contains details about the ACSS Debit payment method options.
        attr_accessor :acss_debit
        # contains details about the Affirm payment method options.
        attr_accessor :affirm
        # contains details about the Afterpay Clearpay payment method options.
        attr_accessor :afterpay_clearpay
        # contains details about the Alipay payment method options.
        attr_accessor :alipay
        # contains details about the Alma payment method options.
        attr_accessor :alma
        # contains details about the AmazonPay payment method options.
        attr_accessor :amazon_pay
        # contains details about the AU Becs Debit payment method options.
        attr_accessor :au_becs_debit
        # contains details about the Bacs Debit payment method options.
        attr_accessor :bacs_debit
        # contains details about the Bancontact payment method options.
        attr_accessor :bancontact
        # contains details about the Billie payment method options.
        attr_accessor :billie
        # contains details about the Boleto payment method options.
        attr_accessor :boleto
        # contains details about the Card payment method options.
        attr_accessor :card
        # contains details about the Cashapp Pay payment method options.
        attr_accessor :cashapp
        # contains details about the Customer Balance payment method options.
        attr_accessor :customer_balance
        # contains details about the DemoPay payment method options.
        attr_accessor :demo_pay
        # contains details about the EPS payment method options.
        attr_accessor :eps
        # contains details about the FPX payment method options.
        attr_accessor :fpx
        # contains details about the Giropay payment method options.
        attr_accessor :giropay
        # contains details about the Grabpay payment method options.
        attr_accessor :grabpay
        # contains details about the Ideal payment method options.
        attr_accessor :ideal
        # contains details about the Kakao Pay payment method options.
        attr_accessor :kakao_pay
        # contains details about the Klarna payment method options.
        attr_accessor :klarna
        # contains details about the Konbini payment method options.
        attr_accessor :konbini
        # contains details about the Korean card payment method options.
        attr_accessor :kr_card
        # contains details about the Link payment method options.
        attr_accessor :link
        # contains details about the Mobilepay payment method options.
        attr_accessor :mobilepay
        # contains details about the Multibanco payment method options.
        attr_accessor :multibanco
        # contains details about the Naver Pay payment method options.
        attr_accessor :naver_pay
        # contains details about the OXXO payment method options.
        attr_accessor :oxxo
        # contains details about the P24 payment method options.
        attr_accessor :p24
        # contains details about the Pay By Bank payment method options.
        attr_accessor :pay_by_bank
        # contains details about the PAYCO payment method options.
        attr_accessor :payco
        # contains details about the PayNow payment method options.
        attr_accessor :paynow
        # contains details about the PayPal payment method options.
        attr_accessor :paypal
        # contains details about the Pix payment method options.
        attr_accessor :pix
        # contains details about the RevolutPay payment method options.
        attr_accessor :revolut_pay
        # contains details about the Samsung Pay payment method options.
        attr_accessor :samsung_pay
        # contains details about the Satispay payment method options.
        attr_accessor :satispay
        # contains details about the Sepa Debit payment method options.
        attr_accessor :sepa_debit
        # contains details about the Sofort payment method options.
        attr_accessor :sofort
        # contains details about the Swish payment method options.
        attr_accessor :swish
        # contains details about the TWINT payment method options.
        attr_accessor :twint
        # contains details about the Us Bank Account payment method options.
        attr_accessor :us_bank_account
        # contains details about the WeChat Pay payment method options.
        attr_accessor :wechat_pay

        def initialize(
          acss_debit: nil,
          affirm: nil,
          afterpay_clearpay: nil,
          alipay: nil,
          alma: nil,
          amazon_pay: nil,
          au_becs_debit: nil,
          bacs_debit: nil,
          bancontact: nil,
          billie: nil,
          boleto: nil,
          card: nil,
          cashapp: nil,
          customer_balance: nil,
          demo_pay: nil,
          eps: nil,
          fpx: nil,
          giropay: nil,
          grabpay: nil,
          ideal: nil,
          kakao_pay: nil,
          klarna: nil,
          konbini: nil,
          kr_card: nil,
          link: nil,
          mobilepay: nil,
          multibanco: nil,
          naver_pay: nil,
          oxxo: nil,
          p24: nil,
          pay_by_bank: nil,
          payco: nil,
          paynow: nil,
          paypal: nil,
          pix: nil,
          revolut_pay: nil,
          samsung_pay: nil,
          satispay: nil,
          sepa_debit: nil,
          sofort: nil,
          swish: nil,
          twint: nil,
          us_bank_account: nil,
          wechat_pay: nil
        )
          @acss_debit = acss_debit
          @affirm = affirm
          @afterpay_clearpay = afterpay_clearpay
          @alipay = alipay
          @alma = alma
          @amazon_pay = amazon_pay
          @au_becs_debit = au_becs_debit
          @bacs_debit = bacs_debit
          @bancontact = bancontact
          @billie = billie
          @boleto = boleto
          @card = card
          @cashapp = cashapp
          @customer_balance = customer_balance
          @demo_pay = demo_pay
          @eps = eps
          @fpx = fpx
          @giropay = giropay
          @grabpay = grabpay
          @ideal = ideal
          @kakao_pay = kakao_pay
          @klarna = klarna
          @konbini = konbini
          @kr_card = kr_card
          @link = link
          @mobilepay = mobilepay
          @multibanco = multibanco
          @naver_pay = naver_pay
          @oxxo = oxxo
          @p24 = p24
          @pay_by_bank = pay_by_bank
          @payco = payco
          @paynow = paynow
          @paypal = paypal
          @pix = pix
          @revolut_pay = revolut_pay
          @samsung_pay = samsung_pay
          @satispay = satispay
          @sepa_debit = sepa_debit
          @sofort = sofort
          @swish = swish
          @twint = twint
          @us_bank_account = us_bank_account
          @wechat_pay = wechat_pay
        end
      end

      class Permissions < ::Stripe::RequestParams
        # Determines which entity is allowed to update the shipping details.
        #
        # Default is `client_only`. Stripe Checkout client will automatically update the shipping details. If set to `server_only`, only your server is allowed to update the shipping details.
        #
        # When set to `server_only`, you must add the onShippingDetailsChange event handler when initializing the Stripe Checkout client and manually update the shipping details from your server using the Stripe API.
        attr_accessor :update_shipping_details

        def initialize(update_shipping_details: nil)
          @update_shipping_details = update_shipping_details
        end
      end

      class PhoneNumberCollection < ::Stripe::RequestParams
        # Set to `true` to enable phone number collection.
        #
        # Can only be set in `payment` and `subscription` mode.
        attr_accessor :enabled

        def initialize(enabled: nil)
          @enabled = enabled
        end
      end

      class SavedPaymentMethodOptions < ::Stripe::RequestParams
        # Uses the `allow_redisplay` value of each saved payment method to filter the set presented to a returning customer. By default, only saved payment methods with ’allow_redisplay: ‘always’ are shown in Checkout.
        attr_accessor :allow_redisplay_filters
        # Enable customers to choose if they wish to remove their saved payment methods. Disabled by default.
        attr_accessor :payment_method_remove
        # Enable customers to choose if they wish to save their payment method for future use. Disabled by default.
        attr_accessor :payment_method_save

        def initialize(
          allow_redisplay_filters: nil,
          payment_method_remove: nil,
          payment_method_save: nil
        )
          @allow_redisplay_filters = allow_redisplay_filters
          @payment_method_remove = payment_method_remove
          @payment_method_save = payment_method_save
        end
      end

      class SetupIntentData < ::Stripe::RequestParams
        # An arbitrary string attached to the object. Often useful for displaying to users.
        attr_accessor :description
        # Set of [key-value pairs](https://stripe.com/docs/api/metadata) that you can attach to an object. This can be useful for storing additional information about the object in a structured format. Individual keys can be unset by posting an empty value to them. All keys can be unset by posting an empty value to `metadata`.
        attr_accessor :metadata
        # The Stripe account for which the setup is intended.
        attr_accessor :on_behalf_of

        def initialize(description: nil, metadata: nil, on_behalf_of: nil)
          @description = description
          @metadata = metadata
          @on_behalf_of = on_behalf_of
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

      class ShippingOption < ::Stripe::RequestParams
        class ShippingRateData < ::Stripe::RequestParams
          class DeliveryEstimate < ::Stripe::RequestParams
            class Maximum < ::Stripe::RequestParams
              # A unit of time.
              attr_accessor :unit
              # Must be greater than 0.
              attr_accessor :value

              def initialize(unit: nil, value: nil)
                @unit = unit
                @value = value
              end
            end

            class Minimum < ::Stripe::RequestParams
              # A unit of time.
              attr_accessor :unit
              # Must be greater than 0.
              attr_accessor :value

              def initialize(unit: nil, value: nil)
                @unit = unit
                @value = value
              end
            end
            # The upper bound of the estimated range. If empty, represents no upper bound i.e., infinite.
            attr_accessor :maximum
            # The lower bound of the estimated range. If empty, represents no lower bound.
            attr_accessor :minimum

            def initialize(maximum: nil, minimum: nil)
              @maximum = maximum
              @minimum = minimum
            end
          end

          class FixedAmount < ::Stripe::RequestParams
            class CurrencyOptions < ::Stripe::RequestParams
              # A non-negative integer in cents representing how much to charge.
              attr_accessor :amount
              # Specifies whether the rate is considered inclusive of taxes or exclusive of taxes. One of `inclusive`, `exclusive`, or `unspecified`.
              attr_accessor :tax_behavior

              def initialize(amount: nil, tax_behavior: nil)
                @amount = amount
                @tax_behavior = tax_behavior
              end
            end
            # A non-negative integer in cents representing how much to charge.
            attr_accessor :amount
            # Three-letter [ISO currency code](https://www.iso.org/iso-4217-currency-codes.html), in lowercase. Must be a [supported currency](https://stripe.com/docs/currencies).
            attr_accessor :currency
            # Shipping rates defined in each available currency option. Each key must be a three-letter [ISO currency code](https://www.iso.org/iso-4217-currency-codes.html) and a [supported currency](https://stripe.com/docs/currencies).
            attr_accessor :currency_options

            def initialize(amount: nil, currency: nil, currency_options: nil)
              @amount = amount
              @currency = currency
              @currency_options = currency_options
            end
          end
          # The estimated range for how long shipping will take, meant to be displayable to the customer. This will appear on CheckoutSessions.
          attr_accessor :delivery_estimate
          # The name of the shipping rate, meant to be displayable to the customer. This will appear on CheckoutSessions.
          attr_accessor :display_name
          # Describes a fixed amount to charge for shipping. Must be present if type is `fixed_amount`.
          attr_accessor :fixed_amount
          # Set of [key-value pairs](https://stripe.com/docs/api/metadata) that you can attach to an object. This can be useful for storing additional information about the object in a structured format. Individual keys can be unset by posting an empty value to them. All keys can be unset by posting an empty value to `metadata`.
          attr_accessor :metadata
          # Specifies whether the rate is considered inclusive of taxes or exclusive of taxes. One of `inclusive`, `exclusive`, or `unspecified`.
          attr_accessor :tax_behavior
          # A [tax code](https://stripe.com/docs/tax/tax-categories) ID. The Shipping tax code is `txcd_92010001`.
          attr_accessor :tax_code
          # The type of calculation to use on the shipping rate.
          attr_accessor :type

          def initialize(
            delivery_estimate: nil,
            display_name: nil,
            fixed_amount: nil,
            metadata: nil,
            tax_behavior: nil,
            tax_code: nil,
            type: nil
          )
            @delivery_estimate = delivery_estimate
            @display_name = display_name
            @fixed_amount = fixed_amount
            @metadata = metadata
            @tax_behavior = tax_behavior
            @tax_code = tax_code
            @type = type
          end
        end
        # The ID of the Shipping Rate to use for this shipping option.
        attr_accessor :shipping_rate
        # Parameters to be passed to Shipping Rate creation for this shipping option.
        attr_accessor :shipping_rate_data

        def initialize(shipping_rate: nil, shipping_rate_data: nil)
          @shipping_rate = shipping_rate
          @shipping_rate_data = shipping_rate_data
        end
      end

      class SubscriptionData < ::Stripe::RequestParams
        class BillingMode < ::Stripe::RequestParams
          class Flexible < ::Stripe::RequestParams
            # Controls how invoices and invoice items display proration amounts and discount amounts.
            attr_accessor :proration_discounts

            def initialize(proration_discounts: nil)
              @proration_discounts = proration_discounts
            end
          end
          # Configure behavior for flexible billing mode.
          attr_accessor :flexible
          # Controls the calculation and orchestration of prorations and invoices for subscriptions. If no value is passed, the default is `flexible`.
          attr_accessor :type

          def initialize(flexible: nil, type: nil)
            @flexible = flexible
            @type = type
          end
        end

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

        class TransferData < ::Stripe::RequestParams
          # A non-negative decimal between 0 and 100, with at most two decimal places. This represents the percentage of the subscription invoice total that will be transferred to the destination account. By default, the entire amount is transferred to the destination.
          attr_accessor :amount_percent
          # ID of an existing, connected Stripe account.
          attr_accessor :destination

          def initialize(amount_percent: nil, destination: nil)
            @amount_percent = amount_percent
            @destination = destination
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
        # A non-negative decimal between 0 and 100, with at most two decimal places. This represents the percentage of the subscription invoice total that will be transferred to the application owner's Stripe account. To use an application fee percent, the request must be made on behalf of another account, using the `Stripe-Account` header or an OAuth key. For more information, see the application fees [documentation](https://stripe.com/docs/connect/subscriptions#collecting-fees-on-subscriptions).
        attr_accessor :application_fee_percent
        # A future timestamp to anchor the subscription's billing cycle for new subscriptions.
        attr_accessor :billing_cycle_anchor
        # Controls how prorations and invoices for subscriptions are calculated and orchestrated.
        attr_accessor :billing_mode
        # The tax rates that will apply to any subscription item that does not have
        # `tax_rates` set. Invoices created will have their `default_tax_rates` populated
        # from the subscription.
        attr_accessor :default_tax_rates
        # The subscription's description, meant to be displayable to the customer.
        # Use this field to optionally store an explanation of the subscription
        # for rendering in the [customer portal](https://stripe.com/docs/customer-management).
        attr_accessor :description
        # All invoices will be billed using the specified settings.
        attr_accessor :invoice_settings
        # Set of [key-value pairs](https://stripe.com/docs/api/metadata) that you can attach to an object. This can be useful for storing additional information about the object in a structured format. Individual keys can be unset by posting an empty value to them. All keys can be unset by posting an empty value to `metadata`.
        attr_accessor :metadata
        # The account on behalf of which to charge, for each of the subscription's invoices.
        attr_accessor :on_behalf_of
        # Determines how to handle prorations resulting from the `billing_cycle_anchor`. If no value is passed, the default is `create_prorations`.
        attr_accessor :proration_behavior
        # If specified, the funds from the subscription's invoices will be transferred to the destination and the ID of the resulting transfers will be found on the resulting charges.
        attr_accessor :transfer_data
        # Unix timestamp representing the end of the trial period the customer will get before being charged for the first time. Has to be at least 48 hours in the future.
        attr_accessor :trial_end
        # Integer representing the number of trial period days before the customer is charged for the first time. Has to be at least 1.
        attr_accessor :trial_period_days
        # Settings related to subscription trials.
        attr_accessor :trial_settings

        def initialize(
          application_fee_percent: nil,
          billing_cycle_anchor: nil,
          billing_mode: nil,
          default_tax_rates: nil,
          description: nil,
          invoice_settings: nil,
          metadata: nil,
          on_behalf_of: nil,
          proration_behavior: nil,
          transfer_data: nil,
          trial_end: nil,
          trial_period_days: nil,
          trial_settings: nil
        )
          @application_fee_percent = application_fee_percent
          @billing_cycle_anchor = billing_cycle_anchor
          @billing_mode = billing_mode
          @default_tax_rates = default_tax_rates
          @description = description
          @invoice_settings = invoice_settings
          @metadata = metadata
          @on_behalf_of = on_behalf_of
          @proration_behavior = proration_behavior
          @transfer_data = transfer_data
          @trial_end = trial_end
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

      class WalletOptions < ::Stripe::RequestParams
        class Link < ::Stripe::RequestParams
          # Specifies whether Checkout should display Link as a payment option. By default, Checkout will display all the supported wallets that the Checkout Session was created with. This is the `auto` behavior, and it is the default choice.
          attr_accessor :display

          def initialize(display: nil)
            @display = display
          end
        end
        # contains details about the Link wallet options.
        attr_accessor :link

        def initialize(link: nil)
          @link = link
        end
      end
      # Settings for price localization with [Adaptive Pricing](https://docs.stripe.com/payments/checkout/adaptive-pricing).
      attr_accessor :adaptive_pricing
      # Configure actions after a Checkout Session has expired.
      attr_accessor :after_expiration
      # Enables user redeemable promotion codes.
      attr_accessor :allow_promotion_codes
      # Settings for automatic tax lookup for this session and resulting payments, invoices, and subscriptions.
      attr_accessor :automatic_tax
      # Specify whether Checkout should collect the customer's billing address. Defaults to `auto`.
      attr_accessor :billing_address_collection
      # The branding settings for the Checkout Session. This parameter is not allowed if ui_mode is `custom`.
      attr_accessor :branding_settings
      # If set, Checkout displays a back button and customers will be directed to this URL if they decide to cancel payment and return to your website. This parameter is not allowed if ui_mode is `embedded` or `custom`.
      attr_accessor :cancel_url
      # A unique string to reference the Checkout Session. This can be a
      # customer ID, a cart ID, or similar, and can be used to reconcile the
      # session with your internal systems.
      attr_accessor :client_reference_id
      # Configure fields for the Checkout Session to gather active consent from customers.
      attr_accessor :consent_collection
      # Three-letter [ISO currency code](https://www.iso.org/iso-4217-currency-codes.html), in lowercase. Must be a [supported currency](https://stripe.com/docs/currencies). Required in `setup` mode when `payment_method_types` is not set.
      attr_accessor :currency
      # Collect additional information from your customer using custom fields. Up to 3 fields are supported.
      attr_accessor :custom_fields
      # Display additional text for your customers using custom text.
      attr_accessor :custom_text
      # ID of an existing Customer, if one exists. In `payment` mode, the customer’s most recently saved card
      # payment method will be used to prefill the email, name, card details, and billing address
      # on the Checkout page. In `subscription` mode, the customer’s [default payment method](https://stripe.com/docs/api/customers/update#update_customer-invoice_settings-default_payment_method)
      # will be used if it’s a card, otherwise the most recently saved card will be used. A valid billing address, billing name and billing email are required on the payment method for Checkout to prefill the customer's card details.
      #
      # If the Customer already has a valid [email](https://stripe.com/docs/api/customers/object#customer_object-email) set, the email will be prefilled and not editable in Checkout.
      # If the Customer does not have a valid `email`, Checkout will set the email entered during the session on the Customer.
      #
      # If blank for Checkout Sessions in `subscription` mode or with `customer_creation` set as `always` in `payment` mode, Checkout will create a new Customer object based on information provided during the payment flow.
      #
      # You can set [`payment_intent_data.setup_future_usage`](https://stripe.com/docs/api/checkout/sessions/create#create_checkout_session-payment_intent_data-setup_future_usage) to have Checkout automatically attach the payment method to the Customer you pass in for future reuse.
      attr_accessor :customer
      # Configure whether a Checkout Session creates a [Customer](https://stripe.com/docs/api/customers) during Session confirmation.
      #
      # When a Customer is not created, you can still retrieve email, address, and other customer data entered in Checkout
      # with [customer_details](https://stripe.com/docs/api/checkout/sessions/object#checkout_session_object-customer_details).
      #
      # Sessions that don't create Customers instead are grouped by [guest customers](https://stripe.com/docs/payments/checkout/guest-customers)
      # in the Dashboard. Promotion codes limited to first time customers will return invalid for these Sessions.
      #
      # Can only be set in `payment` and `setup` mode.
      attr_accessor :customer_creation
      # If provided, this value will be used when the Customer object is created.
      # If not provided, customers will be asked to enter their email address.
      # Use this parameter to prefill customer data if you already have an email
      # on file. To access information about the customer once a session is
      # complete, use the `customer` field.
      attr_accessor :customer_email
      # Controls what fields on Customer can be updated by the Checkout Session. Can only be provided when `customer` is provided.
      attr_accessor :customer_update
      # The coupon or promotion code to apply to this Session. Currently, only up to one may be specified.
      attr_accessor :discounts
      # A list of the types of payment methods (e.g., `card`) that should be excluded from this Checkout Session. This should only be used when payment methods for this Checkout Session are managed through the [Stripe Dashboard](https://dashboard.stripe.com/settings/payment_methods).
      attr_accessor :excluded_payment_method_types
      # Specifies which fields in the response should be expanded.
      attr_accessor :expand
      # The Epoch time in seconds at which the Checkout Session will expire. It can be anywhere from 30 minutes to 24 hours after Checkout Session creation. By default, this value is 24 hours from creation.
      attr_accessor :expires_at
      # Generate a post-purchase Invoice for one-time payments.
      attr_accessor :invoice_creation
      # A list of items the customer is purchasing. Use this parameter to pass one-time or recurring [Prices](https://stripe.com/docs/api/prices). The parameter is required for `payment` and `subscription` mode.
      #
      # For `payment` mode, there is a maximum of 100 line items, however it is recommended to consolidate line items if there are more than a few dozen.
      #
      # For `subscription` mode, there is a maximum of 20 line items with recurring Prices and 20 line items with one-time Prices. Line items with one-time Prices will be on the initial invoice only.
      attr_accessor :line_items
      # The IETF language tag of the locale Checkout is displayed in. If blank or `auto`, the browser's locale is used.
      attr_accessor :locale
      # Set of [key-value pairs](https://stripe.com/docs/api/metadata) that you can attach to an object. This can be useful for storing additional information about the object in a structured format. Individual keys can be unset by posting an empty value to them. All keys can be unset by posting an empty value to `metadata`.
      attr_accessor :metadata
      # The mode of the Checkout Session. Pass `subscription` if the Checkout Session includes at least one recurring item.
      attr_accessor :mode
      # Controls name collection settings for the session.
      #
      # You can configure Checkout to collect your customers' business names, individual names, or both. Each name field can be either required or optional.
      #
      # If a [Customer](https://stripe.com/docs/api/customers) is created or provided, the names can be saved to the Customer object as well.
      attr_accessor :name_collection
      # A list of optional items the customer can add to their order at checkout. Use this parameter to pass one-time or recurring [Prices](https://stripe.com/docs/api/prices).
      #
      # There is a maximum of 10 optional items allowed on a Checkout Session, and the existing limits on the number of line items allowed on a Checkout Session apply to the combined number of line items and optional items.
      #
      # For `payment` mode, there is a maximum of 100 combined line items and optional items, however it is recommended to consolidate items if there are more than a few dozen.
      #
      # For `subscription` mode, there is a maximum of 20 line items and optional items with recurring Prices and 20 line items and optional items with one-time Prices.
      attr_accessor :optional_items
      # Where the user is coming from. This informs the optimizations that are applied to the session.
      attr_accessor :origin_context
      # A subset of parameters to be passed to PaymentIntent creation for Checkout Sessions in `payment` mode.
      attr_accessor :payment_intent_data
      # Specify whether Checkout should collect a payment method. When set to `if_required`, Checkout will not collect a payment method when the total due for the session is 0.
      # This may occur if the Checkout Session includes a free trial or a discount.
      #
      # Can only be set in `subscription` mode. Defaults to `always`.
      #
      # If you'd like information on how to collect a payment method outside of Checkout, read the guide on configuring [subscriptions with a free trial](https://stripe.com/docs/payments/checkout/free-trials).
      attr_accessor :payment_method_collection
      # The ID of the payment method configuration to use with this Checkout session.
      attr_accessor :payment_method_configuration
      # This parameter allows you to set some attributes on the payment method created during a Checkout session.
      attr_accessor :payment_method_data
      # Payment-method-specific configuration.
      attr_accessor :payment_method_options
      # A list of the types of payment methods (e.g., `card`) this Checkout Session can accept.
      #
      # You can omit this attribute to manage your payment methods from the [Stripe Dashboard](https://dashboard.stripe.com/settings/payment_methods).
      # See [Dynamic Payment Methods](https://stripe.com/docs/payments/payment-methods/integration-options#using-dynamic-payment-methods) for more details.
      #
      # Read more about the supported payment methods and their requirements in our [payment
      # method details guide](/docs/payments/checkout/payment-methods).
      #
      # If multiple payment methods are passed, Checkout will dynamically reorder them to
      # prioritize the most relevant payment methods based on the customer's location and
      # other characteristics.
      attr_accessor :payment_method_types
      # This property is used to set up permissions for various actions (e.g., update) on the CheckoutSession object. Can only be set when creating `embedded` or `custom` sessions.
      #
      # For specific permissions, please refer to their dedicated subsections, such as `permissions.update_shipping_details`.
      attr_accessor :permissions
      # Controls phone number collection settings for the session.
      #
      # We recommend that you review your privacy policy and check with your legal contacts
      # before using this feature. Learn more about [collecting phone numbers with Checkout](https://stripe.com/docs/payments/checkout/phone-numbers).
      attr_accessor :phone_number_collection
      # This parameter applies to `ui_mode: embedded`. Learn more about the [redirect behavior](https://stripe.com/docs/payments/checkout/custom-success-page?payment-ui=embedded-form) of embedded sessions. Defaults to `always`.
      attr_accessor :redirect_on_completion
      # The URL to redirect your customer back to after they authenticate or cancel their payment on the
      # payment method's app or site. This parameter is required if `ui_mode` is `embedded` or `custom`
      # and redirect-based payment methods are enabled on the session.
      attr_accessor :return_url
      # Controls saved payment method settings for the session. Only available in `payment` and `subscription` mode.
      attr_accessor :saved_payment_method_options
      # A subset of parameters to be passed to SetupIntent creation for Checkout Sessions in `setup` mode.
      attr_accessor :setup_intent_data
      # When set, provides configuration for Checkout to collect a shipping address from a customer.
      attr_accessor :shipping_address_collection
      # The shipping rate options to apply to this Session. Up to a maximum of 5.
      attr_accessor :shipping_options
      # Describes the type of transaction being performed by Checkout in order
      # to customize relevant text on the page, such as the submit button.
      #  `submit_type` can only be specified on Checkout Sessions in
      # `payment` or `subscription` mode. If blank or `auto`, `pay` is used.
      attr_accessor :submit_type
      # A subset of parameters to be passed to subscription creation for Checkout Sessions in `subscription` mode.
      attr_accessor :subscription_data
      # The URL to which Stripe should send customers when payment or setup
      # is complete.
      # This parameter is not allowed if ui_mode is `embedded` or `custom`. If you'd like to use
      # information from the successful Checkout Session on your page, read the
      # guide on [customizing your success page](https://stripe.com/docs/payments/checkout/custom-success-page).
      attr_accessor :success_url
      # Controls tax ID collection during checkout.
      attr_accessor :tax_id_collection
      # The UI mode of the Session. Defaults to `hosted`.
      attr_accessor :ui_mode
      # Wallet-specific configuration.
      attr_accessor :wallet_options

      def initialize(
        adaptive_pricing: nil,
        after_expiration: nil,
        allow_promotion_codes: nil,
        automatic_tax: nil,
        billing_address_collection: nil,
        branding_settings: nil,
        cancel_url: nil,
        client_reference_id: nil,
        consent_collection: nil,
        currency: nil,
        custom_fields: nil,
        custom_text: nil,
        customer: nil,
        customer_creation: nil,
        customer_email: nil,
        customer_update: nil,
        discounts: nil,
        excluded_payment_method_types: nil,
        expand: nil,
        expires_at: nil,
        invoice_creation: nil,
        line_items: nil,
        locale: nil,
        metadata: nil,
        mode: nil,
        name_collection: nil,
        optional_items: nil,
        origin_context: nil,
        payment_intent_data: nil,
        payment_method_collection: nil,
        payment_method_configuration: nil,
        payment_method_data: nil,
        payment_method_options: nil,
        payment_method_types: nil,
        permissions: nil,
        phone_number_collection: nil,
        redirect_on_completion: nil,
        return_url: nil,
        saved_payment_method_options: nil,
        setup_intent_data: nil,
        shipping_address_collection: nil,
        shipping_options: nil,
        submit_type: nil,
        subscription_data: nil,
        success_url: nil,
        tax_id_collection: nil,
        ui_mode: nil,
        wallet_options: nil
      )
        @adaptive_pricing = adaptive_pricing
        @after_expiration = after_expiration
        @allow_promotion_codes = allow_promotion_codes
        @automatic_tax = automatic_tax
        @billing_address_collection = billing_address_collection
        @branding_settings = branding_settings
        @cancel_url = cancel_url
        @client_reference_id = client_reference_id
        @consent_collection = consent_collection
        @currency = currency
        @custom_fields = custom_fields
        @custom_text = custom_text
        @customer = customer
        @customer_creation = customer_creation
        @customer_email = customer_email
        @customer_update = customer_update
        @discounts = discounts
        @excluded_payment_method_types = excluded_payment_method_types
        @expand = expand
        @expires_at = expires_at
        @invoice_creation = invoice_creation
        @line_items = line_items
        @locale = locale
        @metadata = metadata
        @mode = mode
        @name_collection = name_collection
        @optional_items = optional_items
        @origin_context = origin_context
        @payment_intent_data = payment_intent_data
        @payment_method_collection = payment_method_collection
        @payment_method_configuration = payment_method_configuration
        @payment_method_data = payment_method_data
        @payment_method_options = payment_method_options
        @payment_method_types = payment_method_types
        @permissions = permissions
        @phone_number_collection = phone_number_collection
        @redirect_on_completion = redirect_on_completion
        @return_url = return_url
        @saved_payment_method_options = saved_payment_method_options
        @setup_intent_data = setup_intent_data
        @shipping_address_collection = shipping_address_collection
        @shipping_options = shipping_options
        @submit_type = submit_type
        @subscription_data = subscription_data
        @success_url = success_url
        @tax_id_collection = tax_id_collection
        @ui_mode = ui_mode
        @wallet_options = wallet_options
      end
    end
  end
end
