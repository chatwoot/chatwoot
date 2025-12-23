# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  module Checkout
    # A Checkout Session represents your customer's session as they pay for
    # one-time purchases or subscriptions through [Checkout](https://stripe.com/docs/payments/checkout)
    # or [Payment Links](https://stripe.com/docs/payments/payment-links). We recommend creating a
    # new Session each time your customer attempts to pay.
    #
    # Once payment is successful, the Checkout Session will contain a reference
    # to the [Customer](https://stripe.com/docs/api/customers), and either the successful
    # [PaymentIntent](https://stripe.com/docs/api/payment_intents) or an active
    # [Subscription](https://stripe.com/docs/api/subscriptions).
    #
    # You can create a Checkout Session on your server and redirect to its URL
    # to begin Checkout.
    #
    # Related guide: [Checkout quickstart](https://stripe.com/docs/checkout/quickstart)
    class Session < APIResource
      extend Stripe::APIOperations::Create
      extend Stripe::APIOperations::List
      include Stripe::APIOperations::Save

      OBJECT_NAME = "checkout.session"
      def self.object_name
        "checkout.session"
      end

      class AdaptivePricing < ::Stripe::StripeObject
        # If enabled, Adaptive Pricing is available on [eligible sessions](https://docs.stripe.com/payments/currencies/localize-prices/adaptive-pricing?payment-ui=stripe-hosted#restrictions).
        attr_reader :enabled

        def self.inner_class_types
          @inner_class_types = {}
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end

      class AfterExpiration < ::Stripe::StripeObject
        class Recovery < ::Stripe::StripeObject
          # Enables user redeemable promotion codes on the recovered Checkout Sessions. Defaults to `false`
          attr_reader :allow_promotion_codes
          # If `true`, a recovery url will be generated to recover this Checkout Session if it
          # expires before a transaction is completed. It will be attached to the
          # Checkout Session object upon expiration.
          attr_reader :enabled
          # The timestamp at which the recovery URL will expire.
          attr_reader :expires_at
          # URL that creates a new Checkout Session when clicked that is a copy of this expired Checkout Session
          attr_reader :url

          def self.inner_class_types
            @inner_class_types = {}
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end
        # When set, configuration used to recover the Checkout Session on expiry.
        attr_reader :recovery

        def self.inner_class_types
          @inner_class_types = { recovery: Recovery }
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
        # Indicates whether automatic tax is enabled for the session
        attr_reader :enabled
        # The account that's liable for tax. If set, the business address and tax registrations required to perform the tax calculation are loaded from this account. The tax transaction is returned in the report of the connected account.
        attr_reader :liability
        # The tax provider powering automatic tax.
        attr_reader :provider
        # The status of the most recent automated tax calculation for this session.
        attr_reader :status

        def self.inner_class_types
          @inner_class_types = { liability: Liability }
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end

      class BrandingSettings < ::Stripe::StripeObject
        class Icon < ::Stripe::StripeObject
          # The ID of a [File upload](https://stripe.com/docs/api/files) representing the icon. Purpose must be `business_icon`. Required if `type` is `file` and disallowed otherwise.
          attr_reader :file
          # The type of image for the icon. Must be one of `file` or `url`.
          attr_reader :type
          # The URL of the image. Present when `type` is `url`.
          attr_reader :url

          def self.inner_class_types
            @inner_class_types = {}
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end

        class Logo < ::Stripe::StripeObject
          # The ID of a [File upload](https://stripe.com/docs/api/files) representing the logo. Purpose must be `business_logo`. Required if `type` is `file` and disallowed otherwise.
          attr_reader :file
          # The type of image for the logo. Must be one of `file` or `url`.
          attr_reader :type
          # The URL of the image. Present when `type` is `url`.
          attr_reader :url

          def self.inner_class_types
            @inner_class_types = {}
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end
        # A hex color value starting with `#` representing the background color for the Checkout Session.
        attr_reader :background_color
        # The border style for the Checkout Session. Must be one of `rounded`, `rectangular`, or `pill`.
        attr_reader :border_style
        # A hex color value starting with `#` representing the button color for the Checkout Session.
        attr_reader :button_color
        # The display name shown on the Checkout Session.
        attr_reader :display_name
        # The font family for the Checkout Session. Must be one of the [supported font families](https://docs.stripe.com/payments/checkout/customization/appearance?payment-ui=stripe-hosted#font-compatibility).
        attr_reader :font_family
        # The icon for the Checkout Session. You cannot set both `logo` and `icon`.
        attr_reader :icon
        # The logo for the Checkout Session. You cannot set both `logo` and `icon`.
        attr_reader :logo

        def self.inner_class_types
          @inner_class_types = { icon: Icon, logo: Logo }
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end

      class CollectedInformation < ::Stripe::StripeObject
        class ShippingDetails < ::Stripe::StripeObject
          class Address < ::Stripe::StripeObject
            # City, district, suburb, town, or village.
            attr_reader :city
            # Two-letter country code ([ISO 3166-1 alpha-2](https://en.wikipedia.org/wiki/ISO_3166-1_alpha-2)).
            attr_reader :country
            # Address line 1, such as the street, PO Box, or company name.
            attr_reader :line1
            # Address line 2, such as the apartment, suite, unit, or building.
            attr_reader :line2
            # ZIP or postal code.
            attr_reader :postal_code
            # State, county, province, or region.
            attr_reader :state

            def self.inner_class_types
              @inner_class_types = {}
            end

            def self.field_remappings
              @field_remappings = {}
            end
          end
          # Attribute for field address
          attr_reader :address
          # Customer name.
          attr_reader :name

          def self.inner_class_types
            @inner_class_types = { address: Address }
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end
        # Customer’s business name for this Checkout Session
        attr_reader :business_name
        # Customer’s individual name for this Checkout Session
        attr_reader :individual_name
        # Shipping information for this Checkout Session.
        attr_reader :shipping_details

        def self.inner_class_types
          @inner_class_types = { shipping_details: ShippingDetails }
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end

      class Consent < ::Stripe::StripeObject
        # If `opt_in`, the customer consents to receiving promotional communications
        # from the merchant about this Checkout Session.
        attr_reader :promotions
        # If `accepted`, the customer in this Checkout Session has agreed to the merchant's terms of service.
        attr_reader :terms_of_service

        def self.inner_class_types
          @inner_class_types = {}
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
        # If set to `hidden`, it will hide legal text related to the reuse of a payment method.
        attr_reader :payment_method_reuse_agreement
        # If set to `auto`, enables the collection of customer consent for promotional communications. The Checkout
        # Session will determine whether to display an option to opt into promotional communication
        # from the merchant depending on the customer's locale. Only available to US merchants.
        attr_reader :promotions
        # If set to `required`, it requires customers to accept the terms of service before being able to pay.
        attr_reader :terms_of_service

        def self.inner_class_types
          @inner_class_types = { payment_method_reuse_agreement: PaymentMethodReuseAgreement }
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end

      class CurrencyConversion < ::Stripe::StripeObject
        # Total of all items in source currency before discounts or taxes are applied.
        attr_reader :amount_subtotal
        # Total of all items in source currency after discounts and taxes are applied.
        attr_reader :amount_total
        # Exchange rate used to convert source currency amounts to customer currency amounts
        attr_reader :fx_rate
        # Creation currency of the CheckoutSession before localization
        attr_reader :source_currency

        def self.inner_class_types
          @inner_class_types = {}
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
          # The option selected by the customer. This will be the `value` for the option.
          attr_reader :value

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
          # The value entered by the customer, containing only digits.
          attr_reader :value

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
          # The value entered by the customer.
          attr_reader :value

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

      class CustomerDetails < ::Stripe::StripeObject
        class Address < ::Stripe::StripeObject
          # City, district, suburb, town, or village.
          attr_reader :city
          # Two-letter country code ([ISO 3166-1 alpha-2](https://en.wikipedia.org/wiki/ISO_3166-1_alpha-2)).
          attr_reader :country
          # Address line 1, such as the street, PO Box, or company name.
          attr_reader :line1
          # Address line 2, such as the apartment, suite, unit, or building.
          attr_reader :line2
          # ZIP or postal code.
          attr_reader :postal_code
          # State, county, province, or region.
          attr_reader :state

          def self.inner_class_types
            @inner_class_types = {}
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end

        class TaxId < ::Stripe::StripeObject
          # The type of the tax ID, one of `ad_nrt`, `ar_cuit`, `eu_vat`, `bo_tin`, `br_cnpj`, `br_cpf`, `cn_tin`, `co_nit`, `cr_tin`, `do_rcn`, `ec_ruc`, `eu_oss_vat`, `hr_oib`, `pe_ruc`, `ro_tin`, `rs_pib`, `sv_nit`, `uy_ruc`, `ve_rif`, `vn_tin`, `gb_vat`, `nz_gst`, `au_abn`, `au_arn`, `in_gst`, `no_vat`, `no_voec`, `za_vat`, `ch_vat`, `mx_rfc`, `sg_uen`, `ru_inn`, `ru_kpp`, `ca_bn`, `hk_br`, `es_cif`, `tw_vat`, `th_vat`, `jp_cn`, `jp_rn`, `jp_trn`, `li_uid`, `li_vat`, `my_itn`, `us_ein`, `kr_brn`, `ca_qst`, `ca_gst_hst`, `ca_pst_bc`, `ca_pst_mb`, `ca_pst_sk`, `my_sst`, `sg_gst`, `ae_trn`, `cl_tin`, `sa_vat`, `id_npwp`, `my_frp`, `il_vat`, `ge_vat`, `ua_vat`, `is_vat`, `bg_uic`, `hu_tin`, `si_tin`, `ke_pin`, `tr_tin`, `eg_tin`, `ph_tin`, `al_tin`, `bh_vat`, `kz_bin`, `ng_tin`, `om_vat`, `de_stn`, `ch_uid`, `tz_vat`, `uz_vat`, `uz_tin`, `md_vat`, `ma_vat`, `by_tin`, `ao_tin`, `bs_tin`, `bb_tin`, `cd_nif`, `mr_nif`, `me_pib`, `zw_tin`, `ba_tin`, `gn_nif`, `mk_vat`, `sr_fin`, `sn_ninea`, `am_tin`, `np_pan`, `tj_tin`, `ug_tin`, `zm_tin`, `kh_tin`, `aw_tin`, `az_tin`, `bd_bin`, `bj_ifu`, `et_tin`, `kg_tin`, `la_tin`, `cm_niu`, `cv_nif`, `bf_ifu`, or `unknown`
          attr_reader :type
          # The value of the tax ID.
          attr_reader :value

          def self.inner_class_types
            @inner_class_types = {}
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end
        # The customer's address after a completed Checkout Session. Note: This property is populated only for sessions on or after March 30, 2022.
        attr_reader :address
        # The customer's business name after a completed Checkout Session.
        attr_reader :business_name
        # The email associated with the Customer, if one exists, on the Checkout Session after a completed Checkout Session or at time of session expiry.
        # Otherwise, if the customer has consented to promotional content, this value is the most recent valid email provided by the customer on the Checkout form.
        attr_reader :email
        # The customer's individual name after a completed Checkout Session.
        attr_reader :individual_name
        # The customer's name after a completed Checkout Session. Note: This property is populated only for sessions on or after March 30, 2022.
        attr_reader :name
        # The customer's phone number after a completed Checkout Session.
        attr_reader :phone
        # The customer’s tax exempt status after a completed Checkout Session.
        attr_reader :tax_exempt
        # The customer’s tax IDs after a completed Checkout Session.
        attr_reader :tax_ids

        def self.inner_class_types
          @inner_class_types = { address: Address, tax_ids: TaxId }
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end

      class Discount < ::Stripe::StripeObject
        # Coupon attached to the Checkout Session.
        attr_reader :coupon
        # Promotion code attached to the Checkout Session.
        attr_reader :promotion_code

        def self.inner_class_types
          @inner_class_types = {}
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
          # Custom fields displayed on the invoice.
          attr_reader :custom_fields
          # An arbitrary string attached to the object. Often useful for displaying to users.
          attr_reader :description
          # Footer displayed on the invoice.
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
        # Indicates whether invoice creation is enabled for the Checkout Session.
        attr_reader :enabled
        # Attribute for field invoice_data
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
          # Indicates whether business name collection is enabled for the session
          attr_reader :enabled
          # Whether the customer is required to complete the field before completing the Checkout Session. Defaults to `false`.
          attr_reader :optional

          def self.inner_class_types
            @inner_class_types = {}
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end

        class Individual < ::Stripe::StripeObject
          # Indicates whether individual name collection is enabled for the session
          attr_reader :enabled
          # Whether the customer is required to complete the field before completing the Checkout Session. Defaults to `false`.
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
          # The maximum quantity of this item the customer can purchase. By default this value is 99. You can specify a value up to 999999.
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
            # List of Stripe products where this mandate can be selected automatically. Returned when the Session is in `setup` mode.
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
          # Currency supported by the bank account. Returned when the Session is in `setup` mode.
          attr_reader :currency
          # Attribute for field mandate_options
          attr_reader :mandate_options
          # Indicates that you intend to make future payments with this PaymentIntent's payment method.
          #
          # If you provide a Customer with the PaymentIntent, you can use this parameter to [attach the payment method](/payments/save-during-payment) to the Customer after the PaymentIntent is confirmed and the customer completes any required actions. If you don't provide a Customer, you can still [attach](/api/payment_methods/attach) the payment method to a Customer after the transaction completes.
          #
          # If the payment method is `card_present` and isn't a digital wallet, Stripe creates and attaches a [generated_card](/api/charges/object#charge_object-payment_method_details-card_present-generated_card) payment method representing the card to the Customer instead.
          #
          # When processing card payments, Stripe uses `setup_future_usage` to help you comply with regional legislation and network rules, such as [SCA](/strong-customer-authentication).
          attr_reader :setup_future_usage
          # Controls when Stripe will attempt to debit the funds from the customer's account. The date must be a string in YYYY-MM-DD format. The date must be in the future and between 3 and 15 calendar days from now.
          attr_reader :target_date
          # Bank account verification method.
          attr_reader :verification_method

          def self.inner_class_types
            @inner_class_types = { mandate_options: MandateOptions }
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end

        class Affirm < ::Stripe::StripeObject
          # Controls when the funds will be captured from the customer's account.
          attr_reader :capture_method
          # Indicates that you intend to make future payments with this PaymentIntent's payment method.
          #
          # If you provide a Customer with the PaymentIntent, you can use this parameter to [attach the payment method](/payments/save-during-payment) to the Customer after the PaymentIntent is confirmed and the customer completes any required actions. If you don't provide a Customer, you can still [attach](/api/payment_methods/attach) the payment method to a Customer after the transaction completes.
          #
          # If the payment method is `card_present` and isn't a digital wallet, Stripe creates and attaches a [generated_card](/api/charges/object#charge_object-payment_method_details-card_present-generated_card) payment method representing the card to the Customer instead.
          #
          # When processing card payments, Stripe uses `setup_future_usage` to help you comply with regional legislation and network rules, such as [SCA](/strong-customer-authentication).
          attr_reader :setup_future_usage

          def self.inner_class_types
            @inner_class_types = {}
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end

        class AfterpayClearpay < ::Stripe::StripeObject
          # Controls when the funds will be captured from the customer's account.
          attr_reader :capture_method
          # Indicates that you intend to make future payments with this PaymentIntent's payment method.
          #
          # If you provide a Customer with the PaymentIntent, you can use this parameter to [attach the payment method](/payments/save-during-payment) to the Customer after the PaymentIntent is confirmed and the customer completes any required actions. If you don't provide a Customer, you can still [attach](/api/payment_methods/attach) the payment method to a Customer after the transaction completes.
          #
          # If the payment method is `card_present` and isn't a digital wallet, Stripe creates and attaches a [generated_card](/api/charges/object#charge_object-payment_method_details-card_present-generated_card) payment method representing the card to the Customer instead.
          #
          # When processing card payments, Stripe uses `setup_future_usage` to help you comply with regional legislation and network rules, such as [SCA](/strong-customer-authentication).
          attr_reader :setup_future_usage

          def self.inner_class_types
            @inner_class_types = {}
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end

        class Alipay < ::Stripe::StripeObject
          # Indicates that you intend to make future payments with this PaymentIntent's payment method.
          #
          # If you provide a Customer with the PaymentIntent, you can use this parameter to [attach the payment method](/payments/save-during-payment) to the Customer after the PaymentIntent is confirmed and the customer completes any required actions. If you don't provide a Customer, you can still [attach](/api/payment_methods/attach) the payment method to a Customer after the transaction completes.
          #
          # If the payment method is `card_present` and isn't a digital wallet, Stripe creates and attaches a [generated_card](/api/charges/object#charge_object-payment_method_details-card_present-generated_card) payment method representing the card to the Customer instead.
          #
          # When processing card payments, Stripe uses `setup_future_usage` to help you comply with regional legislation and network rules, such as [SCA](/strong-customer-authentication).
          attr_reader :setup_future_usage

          def self.inner_class_types
            @inner_class_types = {}
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end

        class Alma < ::Stripe::StripeObject
          # Controls when the funds will be captured from the customer's account.
          attr_reader :capture_method

          def self.inner_class_types
            @inner_class_types = {}
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end

        class AmazonPay < ::Stripe::StripeObject
          # Controls when the funds will be captured from the customer's account.
          attr_reader :capture_method
          # Indicates that you intend to make future payments with this PaymentIntent's payment method.
          #
          # If you provide a Customer with the PaymentIntent, you can use this parameter to [attach the payment method](/payments/save-during-payment) to the Customer after the PaymentIntent is confirmed and the customer completes any required actions. If you don't provide a Customer, you can still [attach](/api/payment_methods/attach) the payment method to a Customer after the transaction completes.
          #
          # If the payment method is `card_present` and isn't a digital wallet, Stripe creates and attaches a [generated_card](/api/charges/object#charge_object-payment_method_details-card_present-generated_card) payment method representing the card to the Customer instead.
          #
          # When processing card payments, Stripe uses `setup_future_usage` to help you comply with regional legislation and network rules, such as [SCA](/strong-customer-authentication).
          attr_reader :setup_future_usage

          def self.inner_class_types
            @inner_class_types = {}
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end

        class AuBecsDebit < ::Stripe::StripeObject
          # Indicates that you intend to make future payments with this PaymentIntent's payment method.
          #
          # If you provide a Customer with the PaymentIntent, you can use this parameter to [attach the payment method](/payments/save-during-payment) to the Customer after the PaymentIntent is confirmed and the customer completes any required actions. If you don't provide a Customer, you can still [attach](/api/payment_methods/attach) the payment method to a Customer after the transaction completes.
          #
          # If the payment method is `card_present` and isn't a digital wallet, Stripe creates and attaches a [generated_card](/api/charges/object#charge_object-payment_method_details-card_present-generated_card) payment method representing the card to the Customer instead.
          #
          # When processing card payments, Stripe uses `setup_future_usage` to help you comply with regional legislation and network rules, such as [SCA](/strong-customer-authentication).
          attr_reader :setup_future_usage
          # Controls when Stripe will attempt to debit the funds from the customer's account. The date must be a string in YYYY-MM-DD format. The date must be in the future and between 3 and 15 calendar days from now.
          attr_reader :target_date

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
          # Indicates that you intend to make future payments with this PaymentIntent's payment method.
          #
          # If you provide a Customer with the PaymentIntent, you can use this parameter to [attach the payment method](/payments/save-during-payment) to the Customer after the PaymentIntent is confirmed and the customer completes any required actions. If you don't provide a Customer, you can still [attach](/api/payment_methods/attach) the payment method to a Customer after the transaction completes.
          #
          # If the payment method is `card_present` and isn't a digital wallet, Stripe creates and attaches a [generated_card](/api/charges/object#charge_object-payment_method_details-card_present-generated_card) payment method representing the card to the Customer instead.
          #
          # When processing card payments, Stripe uses `setup_future_usage` to help you comply with regional legislation and network rules, such as [SCA](/strong-customer-authentication).
          attr_reader :setup_future_usage
          # Controls when Stripe will attempt to debit the funds from the customer's account. The date must be a string in YYYY-MM-DD format. The date must be in the future and between 3 and 15 calendar days from now.
          attr_reader :target_date

          def self.inner_class_types
            @inner_class_types = { mandate_options: MandateOptions }
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end

        class Bancontact < ::Stripe::StripeObject
          # Indicates that you intend to make future payments with this PaymentIntent's payment method.
          #
          # If you provide a Customer with the PaymentIntent, you can use this parameter to [attach the payment method](/payments/save-during-payment) to the Customer after the PaymentIntent is confirmed and the customer completes any required actions. If you don't provide a Customer, you can still [attach](/api/payment_methods/attach) the payment method to a Customer after the transaction completes.
          #
          # If the payment method is `card_present` and isn't a digital wallet, Stripe creates and attaches a [generated_card](/api/charges/object#charge_object-payment_method_details-card_present-generated_card) payment method representing the card to the Customer instead.
          #
          # When processing card payments, Stripe uses `setup_future_usage` to help you comply with regional legislation and network rules, such as [SCA](/strong-customer-authentication).
          attr_reader :setup_future_usage

          def self.inner_class_types
            @inner_class_types = {}
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end

        class Billie < ::Stripe::StripeObject
          # Controls when the funds will be captured from the customer's account.
          attr_reader :capture_method

          def self.inner_class_types
            @inner_class_types = {}
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end

        class Boleto < ::Stripe::StripeObject
          # The number of calendar days before a Boleto voucher expires. For example, if you create a Boleto voucher on Monday and you set expires_after_days to 2, the Boleto voucher will expire on Wednesday at 23:59 America/Sao_Paulo time.
          attr_reader :expires_after_days
          # Indicates that you intend to make future payments with this PaymentIntent's payment method.
          #
          # If you provide a Customer with the PaymentIntent, you can use this parameter to [attach the payment method](/payments/save-during-payment) to the Customer after the PaymentIntent is confirmed and the customer completes any required actions. If you don't provide a Customer, you can still [attach](/api/payment_methods/attach) the payment method to a Customer after the transaction completes.
          #
          # If the payment method is `card_present` and isn't a digital wallet, Stripe creates and attaches a [generated_card](/api/charges/object#charge_object-payment_method_details-card_present-generated_card) payment method representing the card to the Customer instead.
          #
          # When processing card payments, Stripe uses `setup_future_usage` to help you comply with regional legislation and network rules, such as [SCA](/strong-customer-authentication).
          attr_reader :setup_future_usage

          def self.inner_class_types
            @inner_class_types = {}
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end

        class Card < ::Stripe::StripeObject
          class Installments < ::Stripe::StripeObject
            # Indicates if installments are enabled
            attr_reader :enabled

            def self.inner_class_types
              @inner_class_types = {}
            end

            def self.field_remappings
              @field_remappings = {}
            end
          end

          class Restrictions < ::Stripe::StripeObject
            # Specify the card brands to block in the Checkout Session. If a customer enters or selects a card belonging to a blocked brand, they can't complete the Session.
            attr_reader :brands_blocked

            def self.inner_class_types
              @inner_class_types = {}
            end

            def self.field_remappings
              @field_remappings = {}
            end
          end
          # Controls when the funds will be captured from the customer's account.
          attr_reader :capture_method
          # Attribute for field installments
          attr_reader :installments
          # Request ability to [capture beyond the standard authorization validity window](/payments/extended-authorization) for this CheckoutSession.
          attr_reader :request_extended_authorization
          # Request ability to [increment the authorization](/payments/incremental-authorization) for this CheckoutSession.
          attr_reader :request_incremental_authorization
          # Request ability to make [multiple captures](/payments/multicapture) for this CheckoutSession.
          attr_reader :request_multicapture
          # Request ability to [overcapture](/payments/overcapture) for this CheckoutSession.
          attr_reader :request_overcapture
          # We strongly recommend that you rely on our SCA Engine to automatically prompt your customers for authentication based on risk level and [other requirements](https://stripe.com/docs/strong-customer-authentication). However, if you wish to request 3D Secure based on logic from your own fraud engine, provide this option. If not provided, this value defaults to `automatic`. Read our guide on [manually requesting 3D Secure](https://stripe.com/docs/payments/3d-secure/authentication-flow#manual-three-ds) for more information on how this configuration interacts with Radar and our SCA Engine.
          attr_reader :request_three_d_secure
          # Attribute for field restrictions
          attr_reader :restrictions
          # Indicates that you intend to make future payments with this PaymentIntent's payment method.
          #
          # If you provide a Customer with the PaymentIntent, you can use this parameter to [attach the payment method](/payments/save-during-payment) to the Customer after the PaymentIntent is confirmed and the customer completes any required actions. If you don't provide a Customer, you can still [attach](/api/payment_methods/attach) the payment method to a Customer after the transaction completes.
          #
          # If the payment method is `card_present` and isn't a digital wallet, Stripe creates and attaches a [generated_card](/api/charges/object#charge_object-payment_method_details-card_present-generated_card) payment method representing the card to the Customer instead.
          #
          # When processing card payments, Stripe uses `setup_future_usage` to help you comply with regional legislation and network rules, such as [SCA](/strong-customer-authentication).
          attr_reader :setup_future_usage
          # Provides information about a card payment that customers see on their statements. Concatenated with the Kana prefix (shortened Kana descriptor) or Kana statement descriptor that’s set on the account to form the complete statement descriptor. Maximum 22 characters. On card statements, the *concatenation* of both prefix and suffix (including separators) will appear truncated to 22 characters.
          attr_reader :statement_descriptor_suffix_kana
          # Provides information about a card payment that customers see on their statements. Concatenated with the Kanji prefix (shortened Kanji descriptor) or Kanji statement descriptor that’s set on the account to form the complete statement descriptor. Maximum 17 characters. On card statements, the *concatenation* of both prefix and suffix (including separators) will appear truncated to 17 characters.
          attr_reader :statement_descriptor_suffix_kanji

          def self.inner_class_types
            @inner_class_types = { installments: Installments, restrictions: Restrictions }
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end

        class Cashapp < ::Stripe::StripeObject
          # Controls when the funds will be captured from the customer's account.
          attr_reader :capture_method
          # Indicates that you intend to make future payments with this PaymentIntent's payment method.
          #
          # If you provide a Customer with the PaymentIntent, you can use this parameter to [attach the payment method](/payments/save-during-payment) to the Customer after the PaymentIntent is confirmed and the customer completes any required actions. If you don't provide a Customer, you can still [attach](/api/payment_methods/attach) the payment method to a Customer after the transaction completes.
          #
          # If the payment method is `card_present` and isn't a digital wallet, Stripe creates and attaches a [generated_card](/api/charges/object#charge_object-payment_method_details-card_present-generated_card) payment method representing the card to the Customer instead.
          #
          # When processing card payments, Stripe uses `setup_future_usage` to help you comply with regional legislation and network rules, such as [SCA](/strong-customer-authentication).
          attr_reader :setup_future_usage

          def self.inner_class_types
            @inner_class_types = {}
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end

        class CustomerBalance < ::Stripe::StripeObject
          class BankTransfer < ::Stripe::StripeObject
            class EuBankTransfer < ::Stripe::StripeObject
              # The desired country code of the bank account information. Permitted values include: `BE`, `DE`, `ES`, `FR`, `IE`, or `NL`.
              attr_reader :country

              def self.inner_class_types
                @inner_class_types = {}
              end

              def self.field_remappings
                @field_remappings = {}
              end
            end
            # Attribute for field eu_bank_transfer
            attr_reader :eu_bank_transfer
            # List of address types that should be returned in the financial_addresses response. If not specified, all valid types will be returned.
            #
            # Permitted values include: `sort_code`, `zengin`, `iban`, or `spei`.
            attr_reader :requested_address_types
            # The bank transfer type that this PaymentIntent is allowed to use for funding Permitted values include: `eu_bank_transfer`, `gb_bank_transfer`, `jp_bank_transfer`, `mx_bank_transfer`, or `us_bank_transfer`.
            attr_reader :type

            def self.inner_class_types
              @inner_class_types = { eu_bank_transfer: EuBankTransfer }
            end

            def self.field_remappings
              @field_remappings = {}
            end
          end
          # Attribute for field bank_transfer
          attr_reader :bank_transfer
          # The funding method type to be used when there are not enough funds in the customer balance. Permitted values include: `bank_transfer`.
          attr_reader :funding_type
          # Indicates that you intend to make future payments with this PaymentIntent's payment method.
          #
          # If you provide a Customer with the PaymentIntent, you can use this parameter to [attach the payment method](/payments/save-during-payment) to the Customer after the PaymentIntent is confirmed and the customer completes any required actions. If you don't provide a Customer, you can still [attach](/api/payment_methods/attach) the payment method to a Customer after the transaction completes.
          #
          # If the payment method is `card_present` and isn't a digital wallet, Stripe creates and attaches a [generated_card](/api/charges/object#charge_object-payment_method_details-card_present-generated_card) payment method representing the card to the Customer instead.
          #
          # When processing card payments, Stripe uses `setup_future_usage` to help you comply with regional legislation and network rules, such as [SCA](/strong-customer-authentication).
          attr_reader :setup_future_usage

          def self.inner_class_types
            @inner_class_types = { bank_transfer: BankTransfer }
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end

        class Eps < ::Stripe::StripeObject
          # Indicates that you intend to make future payments with this PaymentIntent's payment method.
          #
          # If you provide a Customer with the PaymentIntent, you can use this parameter to [attach the payment method](/payments/save-during-payment) to the Customer after the PaymentIntent is confirmed and the customer completes any required actions. If you don't provide a Customer, you can still [attach](/api/payment_methods/attach) the payment method to a Customer after the transaction completes.
          #
          # If the payment method is `card_present` and isn't a digital wallet, Stripe creates and attaches a [generated_card](/api/charges/object#charge_object-payment_method_details-card_present-generated_card) payment method representing the card to the Customer instead.
          #
          # When processing card payments, Stripe uses `setup_future_usage` to help you comply with regional legislation and network rules, such as [SCA](/strong-customer-authentication).
          attr_reader :setup_future_usage

          def self.inner_class_types
            @inner_class_types = {}
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end

        class Fpx < ::Stripe::StripeObject
          # Indicates that you intend to make future payments with this PaymentIntent's payment method.
          #
          # If you provide a Customer with the PaymentIntent, you can use this parameter to [attach the payment method](/payments/save-during-payment) to the Customer after the PaymentIntent is confirmed and the customer completes any required actions. If you don't provide a Customer, you can still [attach](/api/payment_methods/attach) the payment method to a Customer after the transaction completes.
          #
          # If the payment method is `card_present` and isn't a digital wallet, Stripe creates and attaches a [generated_card](/api/charges/object#charge_object-payment_method_details-card_present-generated_card) payment method representing the card to the Customer instead.
          #
          # When processing card payments, Stripe uses `setup_future_usage` to help you comply with regional legislation and network rules, such as [SCA](/strong-customer-authentication).
          attr_reader :setup_future_usage

          def self.inner_class_types
            @inner_class_types = {}
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end

        class Giropay < ::Stripe::StripeObject
          # Indicates that you intend to make future payments with this PaymentIntent's payment method.
          #
          # If you provide a Customer with the PaymentIntent, you can use this parameter to [attach the payment method](/payments/save-during-payment) to the Customer after the PaymentIntent is confirmed and the customer completes any required actions. If you don't provide a Customer, you can still [attach](/api/payment_methods/attach) the payment method to a Customer after the transaction completes.
          #
          # If the payment method is `card_present` and isn't a digital wallet, Stripe creates and attaches a [generated_card](/api/charges/object#charge_object-payment_method_details-card_present-generated_card) payment method representing the card to the Customer instead.
          #
          # When processing card payments, Stripe uses `setup_future_usage` to help you comply with regional legislation and network rules, such as [SCA](/strong-customer-authentication).
          attr_reader :setup_future_usage

          def self.inner_class_types
            @inner_class_types = {}
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end

        class Grabpay < ::Stripe::StripeObject
          # Indicates that you intend to make future payments with this PaymentIntent's payment method.
          #
          # If you provide a Customer with the PaymentIntent, you can use this parameter to [attach the payment method](/payments/save-during-payment) to the Customer after the PaymentIntent is confirmed and the customer completes any required actions. If you don't provide a Customer, you can still [attach](/api/payment_methods/attach) the payment method to a Customer after the transaction completes.
          #
          # If the payment method is `card_present` and isn't a digital wallet, Stripe creates and attaches a [generated_card](/api/charges/object#charge_object-payment_method_details-card_present-generated_card) payment method representing the card to the Customer instead.
          #
          # When processing card payments, Stripe uses `setup_future_usage` to help you comply with regional legislation and network rules, such as [SCA](/strong-customer-authentication).
          attr_reader :setup_future_usage

          def self.inner_class_types
            @inner_class_types = {}
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end

        class Ideal < ::Stripe::StripeObject
          # Indicates that you intend to make future payments with this PaymentIntent's payment method.
          #
          # If you provide a Customer with the PaymentIntent, you can use this parameter to [attach the payment method](/payments/save-during-payment) to the Customer after the PaymentIntent is confirmed and the customer completes any required actions. If you don't provide a Customer, you can still [attach](/api/payment_methods/attach) the payment method to a Customer after the transaction completes.
          #
          # If the payment method is `card_present` and isn't a digital wallet, Stripe creates and attaches a [generated_card](/api/charges/object#charge_object-payment_method_details-card_present-generated_card) payment method representing the card to the Customer instead.
          #
          # When processing card payments, Stripe uses `setup_future_usage` to help you comply with regional legislation and network rules, such as [SCA](/strong-customer-authentication).
          attr_reader :setup_future_usage

          def self.inner_class_types
            @inner_class_types = {}
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end

        class KakaoPay < ::Stripe::StripeObject
          # Controls when the funds will be captured from the customer's account.
          attr_reader :capture_method
          # Indicates that you intend to make future payments with this PaymentIntent's payment method.
          #
          # If you provide a Customer with the PaymentIntent, you can use this parameter to [attach the payment method](/payments/save-during-payment) to the Customer after the PaymentIntent is confirmed and the customer completes any required actions. If you don't provide a Customer, you can still [attach](/api/payment_methods/attach) the payment method to a Customer after the transaction completes.
          #
          # If the payment method is `card_present` and isn't a digital wallet, Stripe creates and attaches a [generated_card](/api/charges/object#charge_object-payment_method_details-card_present-generated_card) payment method representing the card to the Customer instead.
          #
          # When processing card payments, Stripe uses `setup_future_usage` to help you comply with regional legislation and network rules, such as [SCA](/strong-customer-authentication).
          attr_reader :setup_future_usage

          def self.inner_class_types
            @inner_class_types = {}
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end

        class Klarna < ::Stripe::StripeObject
          # Controls when the funds will be captured from the customer's account.
          attr_reader :capture_method
          # Indicates that you intend to make future payments with this PaymentIntent's payment method.
          #
          # If you provide a Customer with the PaymentIntent, you can use this parameter to [attach the payment method](/payments/save-during-payment) to the Customer after the PaymentIntent is confirmed and the customer completes any required actions. If you don't provide a Customer, you can still [attach](/api/payment_methods/attach) the payment method to a Customer after the transaction completes.
          #
          # If the payment method is `card_present` and isn't a digital wallet, Stripe creates and attaches a [generated_card](/api/charges/object#charge_object-payment_method_details-card_present-generated_card) payment method representing the card to the Customer instead.
          #
          # When processing card payments, Stripe uses `setup_future_usage` to help you comply with regional legislation and network rules, such as [SCA](/strong-customer-authentication).
          attr_reader :setup_future_usage

          def self.inner_class_types
            @inner_class_types = {}
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end

        class Konbini < ::Stripe::StripeObject
          # The number of calendar days (between 1 and 60) after which Konbini payment instructions will expire. For example, if a PaymentIntent is confirmed with Konbini and `expires_after_days` set to 2 on Monday JST, the instructions will expire on Wednesday 23:59:59 JST.
          attr_reader :expires_after_days
          # Indicates that you intend to make future payments with this PaymentIntent's payment method.
          #
          # If you provide a Customer with the PaymentIntent, you can use this parameter to [attach the payment method](/payments/save-during-payment) to the Customer after the PaymentIntent is confirmed and the customer completes any required actions. If you don't provide a Customer, you can still [attach](/api/payment_methods/attach) the payment method to a Customer after the transaction completes.
          #
          # If the payment method is `card_present` and isn't a digital wallet, Stripe creates and attaches a [generated_card](/api/charges/object#charge_object-payment_method_details-card_present-generated_card) payment method representing the card to the Customer instead.
          #
          # When processing card payments, Stripe uses `setup_future_usage` to help you comply with regional legislation and network rules, such as [SCA](/strong-customer-authentication).
          attr_reader :setup_future_usage

          def self.inner_class_types
            @inner_class_types = {}
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end

        class KrCard < ::Stripe::StripeObject
          # Controls when the funds will be captured from the customer's account.
          attr_reader :capture_method
          # Indicates that you intend to make future payments with this PaymentIntent's payment method.
          #
          # If you provide a Customer with the PaymentIntent, you can use this parameter to [attach the payment method](/payments/save-during-payment) to the Customer after the PaymentIntent is confirmed and the customer completes any required actions. If you don't provide a Customer, you can still [attach](/api/payment_methods/attach) the payment method to a Customer after the transaction completes.
          #
          # If the payment method is `card_present` and isn't a digital wallet, Stripe creates and attaches a [generated_card](/api/charges/object#charge_object-payment_method_details-card_present-generated_card) payment method representing the card to the Customer instead.
          #
          # When processing card payments, Stripe uses `setup_future_usage` to help you comply with regional legislation and network rules, such as [SCA](/strong-customer-authentication).
          attr_reader :setup_future_usage

          def self.inner_class_types
            @inner_class_types = {}
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end

        class Link < ::Stripe::StripeObject
          # Controls when the funds will be captured from the customer's account.
          attr_reader :capture_method
          # Indicates that you intend to make future payments with this PaymentIntent's payment method.
          #
          # If you provide a Customer with the PaymentIntent, you can use this parameter to [attach the payment method](/payments/save-during-payment) to the Customer after the PaymentIntent is confirmed and the customer completes any required actions. If you don't provide a Customer, you can still [attach](/api/payment_methods/attach) the payment method to a Customer after the transaction completes.
          #
          # If the payment method is `card_present` and isn't a digital wallet, Stripe creates and attaches a [generated_card](/api/charges/object#charge_object-payment_method_details-card_present-generated_card) payment method representing the card to the Customer instead.
          #
          # When processing card payments, Stripe uses `setup_future_usage` to help you comply with regional legislation and network rules, such as [SCA](/strong-customer-authentication).
          attr_reader :setup_future_usage

          def self.inner_class_types
            @inner_class_types = {}
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end

        class Mobilepay < ::Stripe::StripeObject
          # Controls when the funds will be captured from the customer's account.
          attr_reader :capture_method
          # Indicates that you intend to make future payments with this PaymentIntent's payment method.
          #
          # If you provide a Customer with the PaymentIntent, you can use this parameter to [attach the payment method](/payments/save-during-payment) to the Customer after the PaymentIntent is confirmed and the customer completes any required actions. If you don't provide a Customer, you can still [attach](/api/payment_methods/attach) the payment method to a Customer after the transaction completes.
          #
          # If the payment method is `card_present` and isn't a digital wallet, Stripe creates and attaches a [generated_card](/api/charges/object#charge_object-payment_method_details-card_present-generated_card) payment method representing the card to the Customer instead.
          #
          # When processing card payments, Stripe uses `setup_future_usage` to help you comply with regional legislation and network rules, such as [SCA](/strong-customer-authentication).
          attr_reader :setup_future_usage

          def self.inner_class_types
            @inner_class_types = {}
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end

        class Multibanco < ::Stripe::StripeObject
          # Indicates that you intend to make future payments with this PaymentIntent's payment method.
          #
          # If you provide a Customer with the PaymentIntent, you can use this parameter to [attach the payment method](/payments/save-during-payment) to the Customer after the PaymentIntent is confirmed and the customer completes any required actions. If you don't provide a Customer, you can still [attach](/api/payment_methods/attach) the payment method to a Customer after the transaction completes.
          #
          # If the payment method is `card_present` and isn't a digital wallet, Stripe creates and attaches a [generated_card](/api/charges/object#charge_object-payment_method_details-card_present-generated_card) payment method representing the card to the Customer instead.
          #
          # When processing card payments, Stripe uses `setup_future_usage` to help you comply with regional legislation and network rules, such as [SCA](/strong-customer-authentication).
          attr_reader :setup_future_usage

          def self.inner_class_types
            @inner_class_types = {}
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end

        class NaverPay < ::Stripe::StripeObject
          # Controls when the funds will be captured from the customer's account.
          attr_reader :capture_method
          # Indicates that you intend to make future payments with this PaymentIntent's payment method.
          #
          # If you provide a Customer with the PaymentIntent, you can use this parameter to [attach the payment method](/payments/save-during-payment) to the Customer after the PaymentIntent is confirmed and the customer completes any required actions. If you don't provide a Customer, you can still [attach](/api/payment_methods/attach) the payment method to a Customer after the transaction completes.
          #
          # If the payment method is `card_present` and isn't a digital wallet, Stripe creates and attaches a [generated_card](/api/charges/object#charge_object-payment_method_details-card_present-generated_card) payment method representing the card to the Customer instead.
          #
          # When processing card payments, Stripe uses `setup_future_usage` to help you comply with regional legislation and network rules, such as [SCA](/strong-customer-authentication).
          attr_reader :setup_future_usage

          def self.inner_class_types
            @inner_class_types = {}
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end

        class Oxxo < ::Stripe::StripeObject
          # The number of calendar days before an OXXO invoice expires. For example, if you create an OXXO invoice on Monday and you set expires_after_days to 2, the OXXO invoice will expire on Wednesday at 23:59 America/Mexico_City time.
          attr_reader :expires_after_days
          # Indicates that you intend to make future payments with this PaymentIntent's payment method.
          #
          # If you provide a Customer with the PaymentIntent, you can use this parameter to [attach the payment method](/payments/save-during-payment) to the Customer after the PaymentIntent is confirmed and the customer completes any required actions. If you don't provide a Customer, you can still [attach](/api/payment_methods/attach) the payment method to a Customer after the transaction completes.
          #
          # If the payment method is `card_present` and isn't a digital wallet, Stripe creates and attaches a [generated_card](/api/charges/object#charge_object-payment_method_details-card_present-generated_card) payment method representing the card to the Customer instead.
          #
          # When processing card payments, Stripe uses `setup_future_usage` to help you comply with regional legislation and network rules, such as [SCA](/strong-customer-authentication).
          attr_reader :setup_future_usage

          def self.inner_class_types
            @inner_class_types = {}
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end

        class P24 < ::Stripe::StripeObject
          # Indicates that you intend to make future payments with this PaymentIntent's payment method.
          #
          # If you provide a Customer with the PaymentIntent, you can use this parameter to [attach the payment method](/payments/save-during-payment) to the Customer after the PaymentIntent is confirmed and the customer completes any required actions. If you don't provide a Customer, you can still [attach](/api/payment_methods/attach) the payment method to a Customer after the transaction completes.
          #
          # If the payment method is `card_present` and isn't a digital wallet, Stripe creates and attaches a [generated_card](/api/charges/object#charge_object-payment_method_details-card_present-generated_card) payment method representing the card to the Customer instead.
          #
          # When processing card payments, Stripe uses `setup_future_usage` to help you comply with regional legislation and network rules, such as [SCA](/strong-customer-authentication).
          attr_reader :setup_future_usage

          def self.inner_class_types
            @inner_class_types = {}
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end

        class Payco < ::Stripe::StripeObject
          # Controls when the funds will be captured from the customer's account.
          attr_reader :capture_method

          def self.inner_class_types
            @inner_class_types = {}
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end

        class Paynow < ::Stripe::StripeObject
          # Indicates that you intend to make future payments with this PaymentIntent's payment method.
          #
          # If you provide a Customer with the PaymentIntent, you can use this parameter to [attach the payment method](/payments/save-during-payment) to the Customer after the PaymentIntent is confirmed and the customer completes any required actions. If you don't provide a Customer, you can still [attach](/api/payment_methods/attach) the payment method to a Customer after the transaction completes.
          #
          # If the payment method is `card_present` and isn't a digital wallet, Stripe creates and attaches a [generated_card](/api/charges/object#charge_object-payment_method_details-card_present-generated_card) payment method representing the card to the Customer instead.
          #
          # When processing card payments, Stripe uses `setup_future_usage` to help you comply with regional legislation and network rules, such as [SCA](/strong-customer-authentication).
          attr_reader :setup_future_usage

          def self.inner_class_types
            @inner_class_types = {}
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end

        class Paypal < ::Stripe::StripeObject
          # Controls when the funds will be captured from the customer's account.
          attr_reader :capture_method
          # Preferred locale of the PayPal checkout page that the customer is redirected to.
          attr_reader :preferred_locale
          # A reference of the PayPal transaction visible to customer which is mapped to PayPal's invoice ID. This must be a globally unique ID if you have configured in your PayPal settings to block multiple payments per invoice ID.
          attr_reader :reference
          # Indicates that you intend to make future payments with this PaymentIntent's payment method.
          #
          # If you provide a Customer with the PaymentIntent, you can use this parameter to [attach the payment method](/payments/save-during-payment) to the Customer after the PaymentIntent is confirmed and the customer completes any required actions. If you don't provide a Customer, you can still [attach](/api/payment_methods/attach) the payment method to a Customer after the transaction completes.
          #
          # If the payment method is `card_present` and isn't a digital wallet, Stripe creates and attaches a [generated_card](/api/charges/object#charge_object-payment_method_details-card_present-generated_card) payment method representing the card to the Customer instead.
          #
          # When processing card payments, Stripe uses `setup_future_usage` to help you comply with regional legislation and network rules, such as [SCA](/strong-customer-authentication).
          attr_reader :setup_future_usage

          def self.inner_class_types
            @inner_class_types = {}
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end

        class Pix < ::Stripe::StripeObject
          # Determines if the amount includes the IOF tax.
          attr_reader :amount_includes_iof
          # The number of seconds after which Pix payment will expire.
          attr_reader :expires_after_seconds
          # Indicates that you intend to make future payments with this PaymentIntent's payment method.
          #
          # If you provide a Customer with the PaymentIntent, you can use this parameter to [attach the payment method](/payments/save-during-payment) to the Customer after the PaymentIntent is confirmed and the customer completes any required actions. If you don't provide a Customer, you can still [attach](/api/payment_methods/attach) the payment method to a Customer after the transaction completes.
          #
          # If the payment method is `card_present` and isn't a digital wallet, Stripe creates and attaches a [generated_card](/api/charges/object#charge_object-payment_method_details-card_present-generated_card) payment method representing the card to the Customer instead.
          #
          # When processing card payments, Stripe uses `setup_future_usage` to help you comply with regional legislation and network rules, such as [SCA](/strong-customer-authentication).
          attr_reader :setup_future_usage

          def self.inner_class_types
            @inner_class_types = {}
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end

        class RevolutPay < ::Stripe::StripeObject
          # Controls when the funds will be captured from the customer's account.
          attr_reader :capture_method
          # Indicates that you intend to make future payments with this PaymentIntent's payment method.
          #
          # If you provide a Customer with the PaymentIntent, you can use this parameter to [attach the payment method](/payments/save-during-payment) to the Customer after the PaymentIntent is confirmed and the customer completes any required actions. If you don't provide a Customer, you can still [attach](/api/payment_methods/attach) the payment method to a Customer after the transaction completes.
          #
          # If the payment method is `card_present` and isn't a digital wallet, Stripe creates and attaches a [generated_card](/api/charges/object#charge_object-payment_method_details-card_present-generated_card) payment method representing the card to the Customer instead.
          #
          # When processing card payments, Stripe uses `setup_future_usage` to help you comply with regional legislation and network rules, such as [SCA](/strong-customer-authentication).
          attr_reader :setup_future_usage

          def self.inner_class_types
            @inner_class_types = {}
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end

        class SamsungPay < ::Stripe::StripeObject
          # Controls when the funds will be captured from the customer's account.
          attr_reader :capture_method

          def self.inner_class_types
            @inner_class_types = {}
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end

        class Satispay < ::Stripe::StripeObject
          # Controls when the funds will be captured from the customer's account.
          attr_reader :capture_method

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
          # Indicates that you intend to make future payments with this PaymentIntent's payment method.
          #
          # If you provide a Customer with the PaymentIntent, you can use this parameter to [attach the payment method](/payments/save-during-payment) to the Customer after the PaymentIntent is confirmed and the customer completes any required actions. If you don't provide a Customer, you can still [attach](/api/payment_methods/attach) the payment method to a Customer after the transaction completes.
          #
          # If the payment method is `card_present` and isn't a digital wallet, Stripe creates and attaches a [generated_card](/api/charges/object#charge_object-payment_method_details-card_present-generated_card) payment method representing the card to the Customer instead.
          #
          # When processing card payments, Stripe uses `setup_future_usage` to help you comply with regional legislation and network rules, such as [SCA](/strong-customer-authentication).
          attr_reader :setup_future_usage
          # Controls when Stripe will attempt to debit the funds from the customer's account. The date must be a string in YYYY-MM-DD format. The date must be in the future and between 3 and 15 calendar days from now.
          attr_reader :target_date

          def self.inner_class_types
            @inner_class_types = { mandate_options: MandateOptions }
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end

        class Sofort < ::Stripe::StripeObject
          # Indicates that you intend to make future payments with this PaymentIntent's payment method.
          #
          # If you provide a Customer with the PaymentIntent, you can use this parameter to [attach the payment method](/payments/save-during-payment) to the Customer after the PaymentIntent is confirmed and the customer completes any required actions. If you don't provide a Customer, you can still [attach](/api/payment_methods/attach) the payment method to a Customer after the transaction completes.
          #
          # If the payment method is `card_present` and isn't a digital wallet, Stripe creates and attaches a [generated_card](/api/charges/object#charge_object-payment_method_details-card_present-generated_card) payment method representing the card to the Customer instead.
          #
          # When processing card payments, Stripe uses `setup_future_usage` to help you comply with regional legislation and network rules, such as [SCA](/strong-customer-authentication).
          attr_reader :setup_future_usage

          def self.inner_class_types
            @inner_class_types = {}
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end

        class Swish < ::Stripe::StripeObject
          # The order reference that will be displayed to customers in the Swish application. Defaults to the `id` of the Payment Intent.
          attr_reader :reference

          def self.inner_class_types
            @inner_class_types = {}
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end

        class Twint < ::Stripe::StripeObject
          # Indicates that you intend to make future payments with this PaymentIntent's payment method.
          #
          # If you provide a Customer with the PaymentIntent, you can use this parameter to [attach the payment method](/payments/save-during-payment) to the Customer after the PaymentIntent is confirmed and the customer completes any required actions. If you don't provide a Customer, you can still [attach](/api/payment_methods/attach) the payment method to a Customer after the transaction completes.
          #
          # If the payment method is `card_present` and isn't a digital wallet, Stripe creates and attaches a [generated_card](/api/charges/object#charge_object-payment_method_details-card_present-generated_card) payment method representing the card to the Customer instead.
          #
          # When processing card payments, Stripe uses `setup_future_usage` to help you comply with regional legislation and network rules, such as [SCA](/strong-customer-authentication).
          attr_reader :setup_future_usage

          def self.inner_class_types
            @inner_class_types = {}
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
          # Attribute for field financial_connections
          attr_reader :financial_connections
          # Indicates that you intend to make future payments with this PaymentIntent's payment method.
          #
          # If you provide a Customer with the PaymentIntent, you can use this parameter to [attach the payment method](/payments/save-during-payment) to the Customer after the PaymentIntent is confirmed and the customer completes any required actions. If you don't provide a Customer, you can still [attach](/api/payment_methods/attach) the payment method to a Customer after the transaction completes.
          #
          # If the payment method is `card_present` and isn't a digital wallet, Stripe creates and attaches a [generated_card](/api/charges/object#charge_object-payment_method_details-card_present-generated_card) payment method representing the card to the Customer instead.
          #
          # When processing card payments, Stripe uses `setup_future_usage` to help you comply with regional legislation and network rules, such as [SCA](/strong-customer-authentication).
          attr_reader :setup_future_usage
          # Controls when Stripe will attempt to debit the funds from the customer's account. The date must be a string in YYYY-MM-DD format. The date must be in the future and between 3 and 15 calendar days from now.
          attr_reader :target_date
          # Bank account verification method.
          attr_reader :verification_method

          def self.inner_class_types
            @inner_class_types = { financial_connections: FinancialConnections }
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end
        # Attribute for field acss_debit
        attr_reader :acss_debit
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
        # Attribute for field au_becs_debit
        attr_reader :au_becs_debit
        # Attribute for field bacs_debit
        attr_reader :bacs_debit
        # Attribute for field bancontact
        attr_reader :bancontact
        # Attribute for field billie
        attr_reader :billie
        # Attribute for field boleto
        attr_reader :boleto
        # Attribute for field card
        attr_reader :card
        # Attribute for field cashapp
        attr_reader :cashapp
        # Attribute for field customer_balance
        attr_reader :customer_balance
        # Attribute for field eps
        attr_reader :eps
        # Attribute for field fpx
        attr_reader :fpx
        # Attribute for field giropay
        attr_reader :giropay
        # Attribute for field grabpay
        attr_reader :grabpay
        # Attribute for field ideal
        attr_reader :ideal
        # Attribute for field kakao_pay
        attr_reader :kakao_pay
        # Attribute for field klarna
        attr_reader :klarna
        # Attribute for field konbini
        attr_reader :konbini
        # Attribute for field kr_card
        attr_reader :kr_card
        # Attribute for field link
        attr_reader :link
        # Attribute for field mobilepay
        attr_reader :mobilepay
        # Attribute for field multibanco
        attr_reader :multibanco
        # Attribute for field naver_pay
        attr_reader :naver_pay
        # Attribute for field oxxo
        attr_reader :oxxo
        # Attribute for field p24
        attr_reader :p24
        # Attribute for field payco
        attr_reader :payco
        # Attribute for field paynow
        attr_reader :paynow
        # Attribute for field paypal
        attr_reader :paypal
        # Attribute for field pix
        attr_reader :pix
        # Attribute for field revolut_pay
        attr_reader :revolut_pay
        # Attribute for field samsung_pay
        attr_reader :samsung_pay
        # Attribute for field satispay
        attr_reader :satispay
        # Attribute for field sepa_debit
        attr_reader :sepa_debit
        # Attribute for field sofort
        attr_reader :sofort
        # Attribute for field swish
        attr_reader :swish
        # Attribute for field twint
        attr_reader :twint
        # Attribute for field us_bank_account
        attr_reader :us_bank_account

        def self.inner_class_types
          @inner_class_types = {
            acss_debit: AcssDebit,
            affirm: Affirm,
            afterpay_clearpay: AfterpayClearpay,
            alipay: Alipay,
            alma: Alma,
            amazon_pay: AmazonPay,
            au_becs_debit: AuBecsDebit,
            bacs_debit: BacsDebit,
            bancontact: Bancontact,
            billie: Billie,
            boleto: Boleto,
            card: Card,
            cashapp: Cashapp,
            customer_balance: CustomerBalance,
            eps: Eps,
            fpx: Fpx,
            giropay: Giropay,
            grabpay: Grabpay,
            ideal: Ideal,
            kakao_pay: KakaoPay,
            klarna: Klarna,
            konbini: Konbini,
            kr_card: KrCard,
            link: Link,
            mobilepay: Mobilepay,
            multibanco: Multibanco,
            naver_pay: NaverPay,
            oxxo: Oxxo,
            p24: P24,
            payco: Payco,
            paynow: Paynow,
            paypal: Paypal,
            pix: Pix,
            revolut_pay: RevolutPay,
            samsung_pay: SamsungPay,
            satispay: Satispay,
            sepa_debit: SepaDebit,
            sofort: Sofort,
            swish: Swish,
            twint: Twint,
            us_bank_account: UsBankAccount,
          }
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end

      class Permissions < ::Stripe::StripeObject
        # Determines which entity is allowed to update the shipping details.
        #
        # Default is `client_only`. Stripe Checkout client will automatically update the shipping details. If set to `server_only`, only your server is allowed to update the shipping details.
        #
        # When set to `server_only`, you must add the onShippingDetailsChange event handler when initializing the Stripe Checkout client and manually update the shipping details from your server using the Stripe API.
        attr_reader :update_shipping_details

        def self.inner_class_types
          @inner_class_types = {}
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end

      class PhoneNumberCollection < ::Stripe::StripeObject
        # Indicates whether phone number collection is enabled for the session
        attr_reader :enabled

        def self.inner_class_types
          @inner_class_types = {}
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

      class SavedPaymentMethodOptions < ::Stripe::StripeObject
        # Uses the `allow_redisplay` value of each saved payment method to filter the set presented to a returning customer. By default, only saved payment methods with ’allow_redisplay: ‘always’ are shown in Checkout.
        attr_reader :allow_redisplay_filters
        # Enable customers to choose if they wish to remove their saved payment methods. Disabled by default.
        attr_reader :payment_method_remove
        # Enable customers to choose if they wish to save their payment method for future use. Disabled by default.
        attr_reader :payment_method_save

        def self.inner_class_types
          @inner_class_types = {}
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end

      class ShippingAddressCollection < ::Stripe::StripeObject
        # An array of two-letter ISO country codes representing which countries Checkout should provide as options for
        # shipping locations. Unsupported country codes: `AS, CX, CC, CU, HM, IR, KP, MH, FM, NF, MP, PW, SY, UM, VI`.
        attr_reader :allowed_countries

        def self.inner_class_types
          @inner_class_types = {}
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end

      class ShippingCost < ::Stripe::StripeObject
        class Tax < ::Stripe::StripeObject
          # Amount of tax applied for this rate.
          attr_reader :amount
          # Tax rates can be applied to [invoices](/invoicing/taxes/tax-rates), [subscriptions](/billing/taxes/tax-rates) and [Checkout Sessions](/payments/checkout/use-manual-tax-rates) to collect tax.
          #
          # Related guide: [Tax rates](/billing/taxes/tax-rates)
          attr_reader :rate
          # The reasoning behind this tax, for example, if the product is tax exempt. The possible values for this field may be extended as new tax rules are supported.
          attr_reader :taxability_reason
          # The amount on which tax is calculated, in cents (or local equivalent).
          attr_reader :taxable_amount

          def self.inner_class_types
            @inner_class_types = {}
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end
        # Total shipping cost before any discounts or taxes are applied.
        attr_reader :amount_subtotal
        # Total tax amount applied due to shipping costs. If no tax was applied, defaults to 0.
        attr_reader :amount_tax
        # Total shipping cost after discounts and taxes are applied.
        attr_reader :amount_total
        # The ID of the ShippingRate for this order.
        attr_reader :shipping_rate
        # The taxes applied to the shipping rate.
        attr_reader :taxes

        def self.inner_class_types
          @inner_class_types = { taxes: Tax }
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end

      class ShippingOption < ::Stripe::StripeObject
        # A non-negative integer in cents representing how much to charge.
        attr_reader :shipping_amount
        # The shipping rate.
        attr_reader :shipping_rate

        def self.inner_class_types
          @inner_class_types = {}
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end

      class TaxIdCollection < ::Stripe::StripeObject
        # Indicates whether tax ID collection is enabled for the session
        attr_reader :enabled
        # Indicates whether a tax ID is required on the payment page
        attr_reader :required

        def self.inner_class_types
          @inner_class_types = {}
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end

      class TotalDetails < ::Stripe::StripeObject
        class Breakdown < ::Stripe::StripeObject
          class Discount < ::Stripe::StripeObject
            # The amount discounted.
            attr_reader :amount
            # A discount represents the actual application of a [coupon](https://stripe.com/docs/api#coupons) or [promotion code](https://stripe.com/docs/api#promotion_codes).
            # It contains information about when the discount began, when it will end, and what it is applied to.
            #
            # Related guide: [Applying discounts to subscriptions](https://stripe.com/docs/billing/subscriptions/discounts)
            attr_reader :discount

            def self.inner_class_types
              @inner_class_types = {}
            end

            def self.field_remappings
              @field_remappings = {}
            end
          end

          class Tax < ::Stripe::StripeObject
            # Amount of tax applied for this rate.
            attr_reader :amount
            # Tax rates can be applied to [invoices](/invoicing/taxes/tax-rates), [subscriptions](/billing/taxes/tax-rates) and [Checkout Sessions](/payments/checkout/use-manual-tax-rates) to collect tax.
            #
            # Related guide: [Tax rates](/billing/taxes/tax-rates)
            attr_reader :rate
            # The reasoning behind this tax, for example, if the product is tax exempt. The possible values for this field may be extended as new tax rules are supported.
            attr_reader :taxability_reason
            # The amount on which tax is calculated, in cents (or local equivalent).
            attr_reader :taxable_amount

            def self.inner_class_types
              @inner_class_types = {}
            end

            def self.field_remappings
              @field_remappings = {}
            end
          end
          # The aggregated discounts.
          attr_reader :discounts
          # The aggregated tax amounts by rate.
          attr_reader :taxes

          def self.inner_class_types
            @inner_class_types = { discounts: Discount, taxes: Tax }
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end
        # This is the sum of all the discounts.
        attr_reader :amount_discount
        # This is the sum of all the shipping amounts.
        attr_reader :amount_shipping
        # This is the sum of all the tax amounts.
        attr_reader :amount_tax
        # Attribute for field breakdown
        attr_reader :breakdown

        def self.inner_class_types
          @inner_class_types = { breakdown: Breakdown }
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end

      class WalletOptions < ::Stripe::StripeObject
        class Link < ::Stripe::StripeObject
          # Describes whether Checkout should display Link. Defaults to `auto`.
          attr_reader :display

          def self.inner_class_types
            @inner_class_types = {}
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end
        # Attribute for field link
        attr_reader :link

        def self.inner_class_types
          @inner_class_types = { link: Link }
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end
      # Settings for price localization with [Adaptive Pricing](https://docs.stripe.com/payments/checkout/adaptive-pricing).
      attr_reader :adaptive_pricing
      # When set, provides configuration for actions to take if this Checkout Session expires.
      attr_reader :after_expiration
      # Enables user redeemable promotion codes.
      attr_reader :allow_promotion_codes
      # Total of all items before discounts or taxes are applied.
      attr_reader :amount_subtotal
      # Total of all items after discounts and taxes are applied.
      attr_reader :amount_total
      # Attribute for field automatic_tax
      attr_reader :automatic_tax
      # Describes whether Checkout should collect the customer's billing address. Defaults to `auto`.
      attr_reader :billing_address_collection
      # Attribute for field branding_settings
      attr_reader :branding_settings
      # If set, Checkout displays a back button and customers will be directed to this URL if they decide to cancel payment and return to your website.
      attr_reader :cancel_url
      # A unique string to reference the Checkout Session. This can be a
      # customer ID, a cart ID, or similar, and can be used to reconcile the
      # Session with your internal systems.
      attr_reader :client_reference_id
      # The client secret of your Checkout Session. Applies to Checkout Sessions with `ui_mode: embedded` or `ui_mode: custom`. For `ui_mode: embedded`, the client secret is to be used when initializing Stripe.js embedded checkout.
      #  For `ui_mode: custom`, use the client secret with [initCheckout](https://stripe.com/docs/js/custom_checkout/init) on your front end.
      attr_reader :client_secret
      # Information about the customer collected within the Checkout Session.
      attr_reader :collected_information
      # Results of `consent_collection` for this session.
      attr_reader :consent
      # When set, provides configuration for the Checkout Session to gather active consent from customers.
      attr_reader :consent_collection
      # Time at which the object was created. Measured in seconds since the Unix epoch.
      attr_reader :created
      # Three-letter [ISO currency code](https://www.iso.org/iso-4217-currency-codes.html), in lowercase. Must be a [supported currency](https://stripe.com/docs/currencies).
      attr_reader :currency
      # Currency conversion details for [Adaptive Pricing](https://docs.stripe.com/payments/checkout/adaptive-pricing) sessions created before 2025-03-31.
      attr_reader :currency_conversion
      # Collect additional information from your customer using custom fields. Up to 3 fields are supported.
      attr_reader :custom_fields
      # Attribute for field custom_text
      attr_reader :custom_text
      # The ID of the customer for this Session.
      # For Checkout Sessions in `subscription` mode or Checkout Sessions with `customer_creation` set as `always` in `payment` mode, Checkout
      # will create a new customer object based on information provided
      # during the payment flow unless an existing customer was provided when
      # the Session was created.
      attr_reader :customer
      # Configure whether a Checkout Session creates a Customer when the Checkout Session completes.
      attr_reader :customer_creation
      # The customer details including the customer's tax exempt status and the customer's tax IDs. Customer's address details are not present on Sessions in `setup` mode.
      attr_reader :customer_details
      # If provided, this value will be used when the Customer object is created.
      # If not provided, customers will be asked to enter their email address.
      # Use this parameter to prefill customer data if you already have an email
      # on file. To access information about the customer once the payment flow is
      # complete, use the `customer` attribute.
      attr_reader :customer_email
      # List of coupons and promotion codes attached to the Checkout Session.
      attr_reader :discounts
      # A list of the types of payment methods (e.g., `card`) that should be excluded from this Checkout Session. This should only be used when payment methods for this Checkout Session are managed through the [Stripe Dashboard](https://dashboard.stripe.com/settings/payment_methods).
      attr_reader :excluded_payment_method_types
      # The timestamp at which the Checkout Session will expire.
      attr_reader :expires_at
      # Unique identifier for the object.
      attr_reader :id
      # ID of the invoice created by the Checkout Session, if it exists.
      attr_reader :invoice
      # Details on the state of invoice creation for the Checkout Session.
      attr_reader :invoice_creation
      # The line items purchased by the customer.
      attr_reader :line_items
      # Has the value `true` if the object exists in live mode or the value `false` if the object exists in test mode.
      attr_reader :livemode
      # The IETF language tag of the locale Checkout is displayed in. If blank or `auto`, the browser's locale is used.
      attr_reader :locale
      # Set of [key-value pairs](https://stripe.com/docs/api/metadata) that you can attach to an object. This can be useful for storing additional information about the object in a structured format.
      attr_reader :metadata
      # The mode of the Checkout Session.
      attr_reader :mode
      # Attribute for field name_collection
      attr_reader :name_collection
      # String representing the object's type. Objects of the same type share the same value.
      attr_reader :object
      # The optional items presented to the customer at checkout.
      attr_reader :optional_items
      # Where the user is coming from. This informs the optimizations that are applied to the session.
      attr_reader :origin_context
      # The ID of the PaymentIntent for Checkout Sessions in `payment` mode. You can't confirm or cancel the PaymentIntent for a Checkout Session. To cancel, [expire the Checkout Session](https://stripe.com/docs/api/checkout/sessions/expire) instead.
      attr_reader :payment_intent
      # The ID of the Payment Link that created this Session.
      attr_reader :payment_link
      # Configure whether a Checkout Session should collect a payment method. Defaults to `always`.
      attr_reader :payment_method_collection
      # Information about the payment method configuration used for this Checkout session if using dynamic payment methods.
      attr_reader :payment_method_configuration_details
      # Payment-method-specific configuration for the PaymentIntent or SetupIntent of this CheckoutSession.
      attr_reader :payment_method_options
      # A list of the types of payment methods (e.g. card) this Checkout
      # Session is allowed to accept.
      attr_reader :payment_method_types
      # The payment status of the Checkout Session, one of `paid`, `unpaid`, or `no_payment_required`.
      # You can use this value to decide when to fulfill your customer's order.
      attr_reader :payment_status
      # This property is used to set up permissions for various actions (e.g., update) on the CheckoutSession object.
      #
      # For specific permissions, please refer to their dedicated subsections, such as `permissions.update_shipping_details`.
      attr_reader :permissions
      # Attribute for field phone_number_collection
      attr_reader :phone_number_collection
      # Attribute for field presentment_details
      attr_reader :presentment_details
      # The ID of the original expired Checkout Session that triggered the recovery flow.
      attr_reader :recovered_from
      # This parameter applies to `ui_mode: embedded`. Learn more about the [redirect behavior](https://stripe.com/docs/payments/checkout/custom-success-page?payment-ui=embedded-form) of embedded sessions. Defaults to `always`.
      attr_reader :redirect_on_completion
      # Applies to Checkout Sessions with `ui_mode: embedded` or `ui_mode: custom`. The URL to redirect your customer back to after they authenticate or cancel their payment on the payment method's app or site.
      attr_reader :return_url
      # Controls saved payment method settings for the session. Only available in `payment` and `subscription` mode.
      attr_reader :saved_payment_method_options
      # The ID of the SetupIntent for Checkout Sessions in `setup` mode. You can't confirm or cancel the SetupIntent for a Checkout Session. To cancel, [expire the Checkout Session](https://stripe.com/docs/api/checkout/sessions/expire) instead.
      attr_reader :setup_intent
      # When set, provides configuration for Checkout to collect a shipping address from a customer.
      attr_reader :shipping_address_collection
      # The details of the customer cost of shipping, including the customer chosen ShippingRate.
      attr_reader :shipping_cost
      # The shipping rate options applied to this Session.
      attr_reader :shipping_options
      # The status of the Checkout Session, one of `open`, `complete`, or `expired`.
      attr_reader :status
      # Describes the type of transaction being performed by Checkout in order to customize
      # relevant text on the page, such as the submit button. `submit_type` can only be
      # specified on Checkout Sessions in `payment` mode. If blank or `auto`, `pay` is used.
      attr_reader :submit_type
      # The ID of the [Subscription](https://stripe.com/docs/api/subscriptions) for Checkout Sessions in `subscription` mode.
      attr_reader :subscription
      # The URL the customer will be directed to after the payment or
      # subscription creation is successful.
      attr_reader :success_url
      # Attribute for field tax_id_collection
      attr_reader :tax_id_collection
      # Tax and discount details for the computed total amount.
      attr_reader :total_details
      # The UI mode of the Session. Defaults to `hosted`.
      attr_reader :ui_mode
      # The URL to the Checkout Session. Applies to Checkout Sessions with `ui_mode: hosted`. Redirect customers to this URL to take them to Checkout. If you’re using [Custom Domains](https://stripe.com/docs/payments/checkout/custom-domains), the URL will use your subdomain. Otherwise, it’ll use `checkout.stripe.com.`
      # This value is only present when the session is active.
      attr_reader :url
      # Wallet-specific configuration for this Checkout Session.
      attr_reader :wallet_options

      # Creates a Checkout Session object.
      def self.create(params = {}, opts = {})
        request_stripe_object(
          method: :post,
          path: "/v1/checkout/sessions",
          params: params,
          opts: opts
        )
      end

      # A Checkout Session can be expired when it is in one of these statuses: open
      #
      # After it expires, a customer can't complete a Checkout Session and customers loading the Checkout Session see a message saying the Checkout Session is expired.
      def expire(params = {}, opts = {})
        request_stripe_object(
          method: :post,
          path: format("/v1/checkout/sessions/%<session>s/expire", { session: CGI.escape(self["id"]) }),
          params: params,
          opts: opts
        )
      end

      # A Checkout Session can be expired when it is in one of these statuses: open
      #
      # After it expires, a customer can't complete a Checkout Session and customers loading the Checkout Session see a message saying the Checkout Session is expired.
      def self.expire(session, params = {}, opts = {})
        request_stripe_object(
          method: :post,
          path: format("/v1/checkout/sessions/%<session>s/expire", { session: CGI.escape(session) }),
          params: params,
          opts: opts
        )
      end

      # Returns a list of Checkout Sessions.
      def self.list(params = {}, opts = {})
        request_stripe_object(
          method: :get,
          path: "/v1/checkout/sessions",
          params: params,
          opts: opts
        )
      end

      # When retrieving a Checkout Session, there is an includable line_items property containing the first handful of those items. There is also a URL where you can retrieve the full (paginated) list of line items.
      def list_line_items(params = {}, opts = {})
        request_stripe_object(
          method: :get,
          path: format("/v1/checkout/sessions/%<session>s/line_items", { session: CGI.escape(self["id"]) }),
          params: params,
          opts: opts
        )
      end

      # When retrieving a Checkout Session, there is an includable line_items property containing the first handful of those items. There is also a URL where you can retrieve the full (paginated) list of line items.
      def self.list_line_items(session, params = {}, opts = {})
        request_stripe_object(
          method: :get,
          path: format("/v1/checkout/sessions/%<session>s/line_items", { session: CGI.escape(session) }),
          params: params,
          opts: opts
        )
      end

      # Updates a Checkout Session object.
      #
      # Related guide: [Dynamically update Checkout](https://docs.stripe.com/payments/checkout/dynamic-updates)
      def self.update(session, params = {}, opts = {})
        request_stripe_object(
          method: :post,
          path: format("/v1/checkout/sessions/%<session>s", { session: CGI.escape(session) }),
          params: params,
          opts: opts
        )
      end

      def self.inner_class_types
        @inner_class_types = {
          adaptive_pricing: AdaptivePricing,
          after_expiration: AfterExpiration,
          automatic_tax: AutomaticTax,
          branding_settings: BrandingSettings,
          collected_information: CollectedInformation,
          consent: Consent,
          consent_collection: ConsentCollection,
          currency_conversion: CurrencyConversion,
          custom_fields: CustomField,
          custom_text: CustomText,
          customer_details: CustomerDetails,
          discounts: Discount,
          invoice_creation: InvoiceCreation,
          name_collection: NameCollection,
          optional_items: OptionalItem,
          payment_method_configuration_details: PaymentMethodConfigurationDetails,
          payment_method_options: PaymentMethodOptions,
          permissions: Permissions,
          phone_number_collection: PhoneNumberCollection,
          presentment_details: PresentmentDetails,
          saved_payment_method_options: SavedPaymentMethodOptions,
          shipping_address_collection: ShippingAddressCollection,
          shipping_cost: ShippingCost,
          shipping_options: ShippingOption,
          tax_id_collection: TaxIdCollection,
          total_details: TotalDetails,
          wallet_options: WalletOptions,
        }
      end

      def self.field_remappings
        @field_remappings = {}
      end
    end
  end
end
