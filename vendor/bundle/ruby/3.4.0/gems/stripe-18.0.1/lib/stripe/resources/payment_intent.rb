# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
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
  class PaymentIntent < APIResource
    extend Stripe::APIOperations::Create
    extend Stripe::APIOperations::List
    extend Stripe::APIOperations::NestedResource
    extend Stripe::APIOperations::Search
    include Stripe::APIOperations::Save

    OBJECT_NAME = "payment_intent"
    def self.object_name
      "payment_intent"
    end

    nested_resource_class_methods :amount_details_line_item, operations: %i[list]

    class AmountDetails < ::Stripe::StripeObject
      class Shipping < ::Stripe::StripeObject
        # If a physical good is being shipped, the cost of shipping represented in the [smallest currency unit](https://stripe.com/docs/currencies#zero-decimal). An integer greater than or equal to 0.
        attr_reader :amount
        # If a physical good is being shipped, the postal code of where it is being shipped from. At most 10 alphanumeric characters long, hyphens are allowed.
        attr_reader :from_postal_code
        # If a physical good is being shipped, the postal code of where it is being shipped to. At most 10 alphanumeric characters long, hyphens are allowed.
        attr_reader :to_postal_code

        def self.inner_class_types
          @inner_class_types = {}
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end

      class Tax < ::Stripe::StripeObject
        # The total amount of tax on the transaction represented in the [smallest currency unit](https://stripe.com/docs/currencies#zero-decimal). Required for L2 rates. An integer greater than or equal to 0.
        #
        # This field is mutually exclusive with the `amount_details[line_items][#][tax][total_tax_amount]` field.
        attr_reader :total_tax_amount

        def self.inner_class_types
          @inner_class_types = {}
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end

      class Tip < ::Stripe::StripeObject
        # Portion of the amount that corresponds to a tip.
        attr_reader :amount

        def self.inner_class_types
          @inner_class_types = {}
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end
      # The total discount applied on the transaction represented in the [smallest currency unit](https://stripe.com/docs/currencies#zero-decimal). An integer greater than 0.
      #
      # This field is mutually exclusive with the `amount_details[line_items][#][discount_amount]` field.
      attr_reader :discount_amount
      # A list of line items, each containing information about a product in the PaymentIntent. There is a maximum of 100 line items.
      attr_reader :line_items
      # Attribute for field shipping
      attr_reader :shipping
      # Attribute for field tax
      attr_reader :tax
      # Attribute for field tip
      attr_reader :tip

      def self.inner_class_types
        @inner_class_types = { shipping: Shipping, tax: Tax, tip: Tip }
      end

      def self.field_remappings
        @field_remappings = {}
      end
    end

    class AutomaticPaymentMethods < ::Stripe::StripeObject
      # Controls whether this PaymentIntent will accept redirect-based payment methods.
      #
      # Redirect-based payment methods may require your customer to be redirected to a payment method's app or site for authentication or additional steps. To [confirm](https://stripe.com/docs/api/payment_intents/confirm) this PaymentIntent, you may be required to provide a `return_url` to redirect customers back to your site after they authenticate or complete the payment.
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

    class Hooks < ::Stripe::StripeObject
      class Inputs < ::Stripe::StripeObject
        class Tax < ::Stripe::StripeObject
          # The [TaxCalculation](https://stripe.com/docs/api/tax/calculations) id
          attr_reader :calculation

          def self.inner_class_types
            @inner_class_types = {}
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end
        # Attribute for field tax
        attr_reader :tax

        def self.inner_class_types
          @inner_class_types = { tax: Tax }
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end
      # Attribute for field inputs
      attr_reader :inputs

      def self.inner_class_types
        @inner_class_types = { inputs: Inputs }
      end

      def self.field_remappings
        @field_remappings = {}
      end
    end

    class LastPaymentError < ::Stripe::StripeObject
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
      class AlipayHandleRedirect < ::Stripe::StripeObject
        # The native data to be used with Alipay SDK you must redirect your customer to in order to authenticate the payment in an Android App.
        attr_reader :native_data
        # The native URL you must redirect your customer to in order to authenticate the payment in an iOS App.
        attr_reader :native_url
        # If the customer does not exit their browser while authenticating, they will be redirected to this specified URL after completion.
        attr_reader :return_url
        # The URL you must redirect your customer to in order to authenticate the payment.
        attr_reader :url

        def self.inner_class_types
          @inner_class_types = {}
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end

      class BoletoDisplayDetails < ::Stripe::StripeObject
        # The timestamp after which the boleto expires.
        attr_reader :expires_at
        # The URL to the hosted boleto voucher page, which allows customers to view the boleto voucher.
        attr_reader :hosted_voucher_url
        # The boleto number.
        attr_reader :number
        # The URL to the downloadable boleto voucher PDF.
        attr_reader :pdf

        def self.inner_class_types
          @inner_class_types = {}
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end

      class CardAwaitNotification < ::Stripe::StripeObject
        # The time that payment will be attempted. If customer approval is required, they need to provide approval before this time.
        attr_reader :charge_attempt_at
        # For payments greater than INR 15000, the customer must provide explicit approval of the payment with their bank. For payments of lower amount, no customer action is required.
        attr_reader :customer_approval_required

        def self.inner_class_types
          @inner_class_types = {}
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end

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

      class DisplayBankTransferInstructions < ::Stripe::StripeObject
        class FinancialAddress < ::Stripe::StripeObject
          class Aba < ::Stripe::StripeObject
            class AccountHolderAddress < ::Stripe::StripeObject
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

            class BankAddress < ::Stripe::StripeObject
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
            # Attribute for field account_holder_address
            attr_reader :account_holder_address
            # The account holder name
            attr_reader :account_holder_name
            # The ABA account number
            attr_reader :account_number
            # The account type
            attr_reader :account_type
            # Attribute for field bank_address
            attr_reader :bank_address
            # The bank name
            attr_reader :bank_name
            # The ABA routing number
            attr_reader :routing_number

            def self.inner_class_types
              @inner_class_types = {
                account_holder_address: AccountHolderAddress,
                bank_address: BankAddress,
              }
            end

            def self.field_remappings
              @field_remappings = {}
            end
          end

          class Iban < ::Stripe::StripeObject
            class AccountHolderAddress < ::Stripe::StripeObject
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

            class BankAddress < ::Stripe::StripeObject
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
            # Attribute for field account_holder_address
            attr_reader :account_holder_address
            # The name of the person or business that owns the bank account
            attr_reader :account_holder_name
            # Attribute for field bank_address
            attr_reader :bank_address
            # The BIC/SWIFT code of the account.
            attr_reader :bic
            # Two-letter country code ([ISO 3166-1 alpha-2](https://en.wikipedia.org/wiki/ISO_3166-1_alpha-2)).
            attr_reader :country
            # The IBAN of the account.
            attr_reader :iban

            def self.inner_class_types
              @inner_class_types = {
                account_holder_address: AccountHolderAddress,
                bank_address: BankAddress,
              }
            end

            def self.field_remappings
              @field_remappings = {}
            end
          end

          class SortCode < ::Stripe::StripeObject
            class AccountHolderAddress < ::Stripe::StripeObject
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

            class BankAddress < ::Stripe::StripeObject
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
            # Attribute for field account_holder_address
            attr_reader :account_holder_address
            # The name of the person or business that owns the bank account
            attr_reader :account_holder_name
            # The account number
            attr_reader :account_number
            # Attribute for field bank_address
            attr_reader :bank_address
            # The six-digit sort code
            attr_reader :sort_code

            def self.inner_class_types
              @inner_class_types = {
                account_holder_address: AccountHolderAddress,
                bank_address: BankAddress,
              }
            end

            def self.field_remappings
              @field_remappings = {}
            end
          end

          class Spei < ::Stripe::StripeObject
            class AccountHolderAddress < ::Stripe::StripeObject
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

            class BankAddress < ::Stripe::StripeObject
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
            # Attribute for field account_holder_address
            attr_reader :account_holder_address
            # The account holder name
            attr_reader :account_holder_name
            # Attribute for field bank_address
            attr_reader :bank_address
            # The three-digit bank code
            attr_reader :bank_code
            # The short banking institution name
            attr_reader :bank_name
            # The CLABE number
            attr_reader :clabe

            def self.inner_class_types
              @inner_class_types = {
                account_holder_address: AccountHolderAddress,
                bank_address: BankAddress,
              }
            end

            def self.field_remappings
              @field_remappings = {}
            end
          end

          class Swift < ::Stripe::StripeObject
            class AccountHolderAddress < ::Stripe::StripeObject
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

            class BankAddress < ::Stripe::StripeObject
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
            # Attribute for field account_holder_address
            attr_reader :account_holder_address
            # The account holder name
            attr_reader :account_holder_name
            # The account number
            attr_reader :account_number
            # The account type
            attr_reader :account_type
            # Attribute for field bank_address
            attr_reader :bank_address
            # The bank name
            attr_reader :bank_name
            # The SWIFT code
            attr_reader :swift_code

            def self.inner_class_types
              @inner_class_types = {
                account_holder_address: AccountHolderAddress,
                bank_address: BankAddress,
              }
            end

            def self.field_remappings
              @field_remappings = {}
            end
          end

          class Zengin < ::Stripe::StripeObject
            class AccountHolderAddress < ::Stripe::StripeObject
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

            class BankAddress < ::Stripe::StripeObject
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
            # Attribute for field account_holder_address
            attr_reader :account_holder_address
            # The account holder name
            attr_reader :account_holder_name
            # The account number
            attr_reader :account_number
            # The bank account type. In Japan, this can only be `futsu` or `toza`.
            attr_reader :account_type
            # Attribute for field bank_address
            attr_reader :bank_address
            # The bank code of the account
            attr_reader :bank_code
            # The bank name of the account
            attr_reader :bank_name
            # The branch code of the account
            attr_reader :branch_code
            # The branch name of the account
            attr_reader :branch_name

            def self.inner_class_types
              @inner_class_types = {
                account_holder_address: AccountHolderAddress,
                bank_address: BankAddress,
              }
            end

            def self.field_remappings
              @field_remappings = {}
            end
          end
          # ABA Records contain U.S. bank account details per the ABA format.
          attr_reader :aba
          # Iban Records contain E.U. bank account details per the SEPA format.
          attr_reader :iban
          # Sort Code Records contain U.K. bank account details per the sort code format.
          attr_reader :sort_code
          # SPEI Records contain Mexico bank account details per the SPEI format.
          attr_reader :spei
          # The payment networks supported by this FinancialAddress
          attr_reader :supported_networks
          # SWIFT Records contain U.S. bank account details per the SWIFT format.
          attr_reader :swift
          # The type of financial address
          attr_reader :type
          # Zengin Records contain Japan bank account details per the Zengin format.
          attr_reader :zengin

          def self.inner_class_types
            @inner_class_types = {
              aba: Aba,
              iban: Iban,
              sort_code: SortCode,
              spei: Spei,
              swift: Swift,
              zengin: Zengin,
            }
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end
        # The remaining amount that needs to be transferred to complete the payment.
        attr_reader :amount_remaining
        # Three-letter [ISO currency code](https://www.iso.org/iso-4217-currency-codes.html), in lowercase. Must be a [supported currency](https://stripe.com/docs/currencies).
        attr_reader :currency
        # A list of financial addresses that can be used to fund the customer balance
        attr_reader :financial_addresses
        # A link to a hosted page that guides your customer through completing the transfer.
        attr_reader :hosted_instructions_url
        # A string identifying this payment. Instruct your customer to include this code in the reference or memo field of their bank transfer.
        attr_reader :reference
        # Type of bank transfer
        attr_reader :type

        def self.inner_class_types
          @inner_class_types = { financial_addresses: FinancialAddress }
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end

      class KonbiniDisplayDetails < ::Stripe::StripeObject
        class Stores < ::Stripe::StripeObject
          class Familymart < ::Stripe::StripeObject
            # The confirmation number.
            attr_reader :confirmation_number
            # The payment code.
            attr_reader :payment_code

            def self.inner_class_types
              @inner_class_types = {}
            end

            def self.field_remappings
              @field_remappings = {}
            end
          end

          class Lawson < ::Stripe::StripeObject
            # The confirmation number.
            attr_reader :confirmation_number
            # The payment code.
            attr_reader :payment_code

            def self.inner_class_types
              @inner_class_types = {}
            end

            def self.field_remappings
              @field_remappings = {}
            end
          end

          class Ministop < ::Stripe::StripeObject
            # The confirmation number.
            attr_reader :confirmation_number
            # The payment code.
            attr_reader :payment_code

            def self.inner_class_types
              @inner_class_types = {}
            end

            def self.field_remappings
              @field_remappings = {}
            end
          end

          class Seicomart < ::Stripe::StripeObject
            # The confirmation number.
            attr_reader :confirmation_number
            # The payment code.
            attr_reader :payment_code

            def self.inner_class_types
              @inner_class_types = {}
            end

            def self.field_remappings
              @field_remappings = {}
            end
          end
          # FamilyMart instruction details.
          attr_reader :familymart
          # Lawson instruction details.
          attr_reader :lawson
          # Ministop instruction details.
          attr_reader :ministop
          # Seicomart instruction details.
          attr_reader :seicomart

          def self.inner_class_types
            @inner_class_types = {
              familymart: Familymart,
              lawson: Lawson,
              ministop: Ministop,
              seicomart: Seicomart,
            }
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end
        # The timestamp at which the pending Konbini payment expires.
        attr_reader :expires_at
        # The URL for the Konbini payment instructions page, which allows customers to view and print a Konbini voucher.
        attr_reader :hosted_voucher_url
        # Attribute for field stores
        attr_reader :stores

        def self.inner_class_types
          @inner_class_types = { stores: Stores }
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end

      class MultibancoDisplayDetails < ::Stripe::StripeObject
        # Entity number associated with this Multibanco payment.
        attr_reader :entity
        # The timestamp at which the Multibanco voucher expires.
        attr_reader :expires_at
        # The URL for the hosted Multibanco voucher page, which allows customers to view a Multibanco voucher.
        attr_reader :hosted_voucher_url
        # Reference number associated with this Multibanco payment.
        attr_reader :reference

        def self.inner_class_types
          @inner_class_types = {}
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end

      class OxxoDisplayDetails < ::Stripe::StripeObject
        # The timestamp after which the OXXO voucher expires.
        attr_reader :expires_after
        # The URL for the hosted OXXO voucher page, which allows customers to view and print an OXXO voucher.
        attr_reader :hosted_voucher_url
        # OXXO reference number.
        attr_reader :number

        def self.inner_class_types
          @inner_class_types = {}
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end

      class PaynowDisplayQrCode < ::Stripe::StripeObject
        # The raw data string used to generate QR code, it should be used together with QR code library.
        attr_reader :data
        # The URL to the hosted PayNow instructions page, which allows customers to view the PayNow QR code.
        attr_reader :hosted_instructions_url
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

      class PixDisplayQrCode < ::Stripe::StripeObject
        # The raw data string used to generate QR code, it should be used together with QR code library.
        attr_reader :data
        # The date (unix timestamp) when the PIX expires.
        attr_reader :expires_at
        # The URL to the hosted pix instructions page, which allows customers to view the pix QR code.
        attr_reader :hosted_instructions_url
        # The image_url_png string used to render png QR code
        attr_reader :image_url_png
        # The image_url_svg string used to render svg QR code
        attr_reader :image_url_svg

        def self.inner_class_types
          @inner_class_types = {}
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end

      class PromptpayDisplayQrCode < ::Stripe::StripeObject
        # The raw data string used to generate QR code, it should be used together with QR code library.
        attr_reader :data
        # The URL to the hosted PromptPay instructions page, which allows customers to view the PromptPay QR code.
        attr_reader :hosted_instructions_url
        # The PNG path used to render the QR code, can be used as the source in an HTML img tag
        attr_reader :image_url_png
        # The SVG path used to render the QR code, can be used as the source in an HTML img tag
        attr_reader :image_url_svg

        def self.inner_class_types
          @inner_class_types = {}
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end

      class RedirectToUrl < ::Stripe::StripeObject
        # If the customer does not exit their browser while authenticating, they will be redirected to this specified URL after completion.
        attr_reader :return_url
        # The URL you must redirect your customer to in order to authenticate the payment.
        attr_reader :url

        def self.inner_class_types
          @inner_class_types = {}
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end

      class SwishHandleRedirectOrDisplayQrCode < ::Stripe::StripeObject
        class QrCode < ::Stripe::StripeObject
          # The raw data string used to generate QR code, it should be used together with QR code library.
          attr_reader :data
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
        # The URL to the hosted Swish instructions page, which allows customers to view the QR code.
        attr_reader :hosted_instructions_url
        # The url for mobile redirect based auth (for internal use only and not typically available in standard API requests).
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

      class WechatPayDisplayQrCode < ::Stripe::StripeObject
        # The data being used to generate QR code
        attr_reader :data
        # The URL to the hosted WeChat Pay instructions page, which allows customers to view the WeChat Pay QR code.
        attr_reader :hosted_instructions_url
        # The base64 image data for a pre-generated QR code
        attr_reader :image_data_url
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

      class WechatPayRedirectToAndroidApp < ::Stripe::StripeObject
        # app_id is the APP ID registered on WeChat open platform
        attr_reader :app_id
        # nonce_str is a random string
        attr_reader :nonce_str
        # package is static value
        attr_reader :package
        # an unique merchant ID assigned by WeChat Pay
        attr_reader :partner_id
        # an unique trading ID assigned by WeChat Pay
        attr_reader :prepay_id
        # A signature
        attr_reader :sign
        # Specifies the current time in epoch format
        attr_reader :timestamp

        def self.inner_class_types
          @inner_class_types = {}
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end

      class WechatPayRedirectToIosApp < ::Stripe::StripeObject
        # An universal link that redirect to WeChat Pay app
        attr_reader :native_url

        def self.inner_class_types
          @inner_class_types = {}
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end
      # Attribute for field alipay_handle_redirect
      attr_reader :alipay_handle_redirect
      # Attribute for field boleto_display_details
      attr_reader :boleto_display_details
      # Attribute for field card_await_notification
      attr_reader :card_await_notification
      # Attribute for field cashapp_handle_redirect_or_display_qr_code
      attr_reader :cashapp_handle_redirect_or_display_qr_code
      # Attribute for field display_bank_transfer_instructions
      attr_reader :display_bank_transfer_instructions
      # Attribute for field konbini_display_details
      attr_reader :konbini_display_details
      # Attribute for field multibanco_display_details
      attr_reader :multibanco_display_details
      # Attribute for field oxxo_display_details
      attr_reader :oxxo_display_details
      # Attribute for field paynow_display_qr_code
      attr_reader :paynow_display_qr_code
      # Attribute for field pix_display_qr_code
      attr_reader :pix_display_qr_code
      # Attribute for field promptpay_display_qr_code
      attr_reader :promptpay_display_qr_code
      # Attribute for field redirect_to_url
      attr_reader :redirect_to_url
      # Attribute for field swish_handle_redirect_or_display_qr_code
      attr_reader :swish_handle_redirect_or_display_qr_code
      # Type of the next action to perform. Refer to the other child attributes under `next_action` for available values. Examples include: `redirect_to_url`, `use_stripe_sdk`, `alipay_handle_redirect`, `oxxo_display_details`, or `verify_with_microdeposits`.
      attr_reader :type
      # When confirming a PaymentIntent with Stripe.js, Stripe.js depends on the contents of this dictionary to invoke authentication flows. The shape of the contents is subject to change and is only intended to be used by Stripe.js.
      attr_reader :use_stripe_sdk
      # Attribute for field verify_with_microdeposits
      attr_reader :verify_with_microdeposits
      # Attribute for field wechat_pay_display_qr_code
      attr_reader :wechat_pay_display_qr_code
      # Attribute for field wechat_pay_redirect_to_android_app
      attr_reader :wechat_pay_redirect_to_android_app
      # Attribute for field wechat_pay_redirect_to_ios_app
      attr_reader :wechat_pay_redirect_to_ios_app

      def self.inner_class_types
        @inner_class_types = {
          alipay_handle_redirect: AlipayHandleRedirect,
          boleto_display_details: BoletoDisplayDetails,
          card_await_notification: CardAwaitNotification,
          cashapp_handle_redirect_or_display_qr_code: CashappHandleRedirectOrDisplayQrCode,
          display_bank_transfer_instructions: DisplayBankTransferInstructions,
          konbini_display_details: KonbiniDisplayDetails,
          multibanco_display_details: MultibancoDisplayDetails,
          oxxo_display_details: OxxoDisplayDetails,
          paynow_display_qr_code: PaynowDisplayQrCode,
          pix_display_qr_code: PixDisplayQrCode,
          promptpay_display_qr_code: PromptpayDisplayQrCode,
          redirect_to_url: RedirectToUrl,
          swish_handle_redirect_or_display_qr_code: SwishHandleRedirectOrDisplayQrCode,
          verify_with_microdeposits: VerifyWithMicrodeposits,
          wechat_pay_display_qr_code: WechatPayDisplayQrCode,
          wechat_pay_redirect_to_android_app: WechatPayRedirectToAndroidApp,
          wechat_pay_redirect_to_ios_app: WechatPayRedirectToIosApp,
        }
      end

      def self.field_remappings
        @field_remappings = {}
      end
    end

    class PaymentDetails < ::Stripe::StripeObject
      # A unique value to identify the customer. This field is available only for card payments.
      #
      # This field is truncated to 25 alphanumeric characters, excluding spaces, before being sent to card networks.
      attr_reader :customer_reference
      # A unique value assigned by the business to identify the transaction. Required for L2 and L3 rates.
      #
      # Required when the Payment Method Types array contains `card`, including when [automatic_payment_methods.enabled](/api/payment_intents/create#create_payment_intent-automatic_payment_methods-enabled) is set to `true`.
      #
      # For Cards, this field is truncated to 25 alphanumeric characters, excluding spaces, before being sent to card networks. For Klarna, this field is truncated to 255 characters and is visible to customers when they view the order in the Klarna app.
      attr_reader :order_reference

      def self.inner_class_types
        @inner_class_types = {}
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
        # Preferred language of the Affirm authorization page that the customer is redirected to.
        attr_reader :preferred_locale
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
        # An internal identifier or reference that this payment corresponds to. You must limit the identifier to 128 characters, and it can only contain letters, numbers, underscores, backslashes, and dashes.
        # This field differs from the statement descriptor and item name.
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
        # Preferred language of the Bancontact authorization page that the customer is redirected to.
        attr_reader :preferred_language
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

      class Blik < ::Stripe::StripeObject
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
          class AvailablePlan < ::Stripe::StripeObject
            # For `fixed_count` installment plans, this is the number of installment payments your customer will make to their credit card.
            attr_reader :count
            # For `fixed_count` installment plans, this is the interval between installment payments your customer will make to their credit card.
            # One of `month`.
            attr_reader :interval
            # Type of installment plan, one of `fixed_count`, `bonus`, or `revolving`.
            attr_reader :type

            def self.inner_class_types
              @inner_class_types = {}
            end

            def self.field_remappings
              @field_remappings = {}
            end
          end

          class Plan < ::Stripe::StripeObject
            # For `fixed_count` installment plans, this is the number of installment payments your customer will make to their credit card.
            attr_reader :count
            # For `fixed_count` installment plans, this is the interval between installment payments your customer will make to their credit card.
            # One of `month`.
            attr_reader :interval
            # Type of installment plan, one of `fixed_count`, `bonus`, or `revolving`.
            attr_reader :type

            def self.inner_class_types
              @inner_class_types = {}
            end

            def self.field_remappings
              @field_remappings = {}
            end
          end
          # Installment plans that may be selected for this PaymentIntent.
          attr_reader :available_plans
          # Whether Installments are enabled for this PaymentIntent.
          attr_reader :enabled
          # Installment plan selected for this PaymentIntent.
          attr_reader :plan

          def self.inner_class_types
            @inner_class_types = { available_plans: AvailablePlan, plan: Plan }
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end

        class MandateOptions < ::Stripe::StripeObject
          # Amount to be charged for future payments.
          attr_reader :amount
          # One of `fixed` or `maximum`. If `fixed`, the `amount` param refers to the exact amount to be charged in future payments. If `maximum`, the amount charged can be up to the value passed for the `amount` param.
          attr_reader :amount_type
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
        # Controls when the funds will be captured from the customer's account.
        attr_reader :capture_method
        # Installment details for this payment.
        #
        # For more information, see the [installments integration guide](https://stripe.com/docs/payments/installments).
        attr_reader :installments
        # Configuration options for setting up an eMandate for cards issued in India.
        attr_reader :mandate_options
        # Selected network to process this payment intent on. Depends on the available networks of the card attached to the payment intent. Can be only set confirm-time.
        attr_reader :network
        # Request ability to [capture beyond the standard authorization validity window](https://stripe.com/docs/payments/extended-authorization) for this PaymentIntent.
        attr_reader :request_extended_authorization
        # Request ability to [increment the authorization](https://stripe.com/docs/payments/incremental-authorization) for this PaymentIntent.
        attr_reader :request_incremental_authorization
        # Request ability to make [multiple captures](https://stripe.com/docs/payments/multicapture) for this PaymentIntent.
        attr_reader :request_multicapture
        # Request ability to [overcapture](https://stripe.com/docs/payments/overcapture) for this PaymentIntent.
        attr_reader :request_overcapture
        # We strongly recommend that you rely on our SCA Engine to automatically prompt your customers for authentication based on risk level and [other requirements](https://stripe.com/docs/strong-customer-authentication). However, if you wish to request 3D Secure based on logic from your own fraud engine, provide this option. If not provided, this value defaults to `automatic`. Read our guide on [manually requesting 3D Secure](https://stripe.com/docs/payments/3d-secure/authentication-flow#manual-three-ds) for more information on how this configuration interacts with Radar and our SCA Engine.
        attr_reader :request_three_d_secure
        # When enabled, using a card that is attached to a customer will require the CVC to be provided again (i.e. using the cvc_token parameter).
        attr_reader :require_cvc_recollection
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
          @inner_class_types = { installments: Installments, mandate_options: MandateOptions }
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end

      class CardPresent < ::Stripe::StripeObject
        class Routing < ::Stripe::StripeObject
          # Requested routing priority
          attr_reader :requested_priority

          def self.inner_class_types
            @inner_class_types = {}
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end
        # Controls when the funds will be captured from the customer's account.
        attr_reader :capture_method
        # Request ability to capture this payment beyond the standard [authorization validity window](https://stripe.com/docs/terminal/features/extended-authorizations#authorization-validity)
        attr_reader :request_extended_authorization
        # Request ability to [increment](https://stripe.com/docs/terminal/features/incremental-authorizations) this PaymentIntent if the combination of MCC and card brand is eligible. Check [incremental_authorization_supported](https://stripe.com/docs/api/charges/object#charge_object-payment_method_details-card_present-incremental_authorization_supported) in the [Confirm](https://stripe.com/docs/api/payment_intents/confirm) response to verify support.
        attr_reader :request_incremental_authorization_support
        # Attribute for field routing
        attr_reader :routing

        def self.inner_class_types
          @inner_class_types = { routing: Routing }
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

      class Crypto < ::Stripe::StripeObject
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

      class InteracPresent < ::Stripe::StripeObject
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
        # Preferred locale of the Klarna checkout page that the customer is redirected to.
        attr_reader :preferred_locale
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
        # An optional 10 to 11 digit numeric-only string determining the confirmation code at applicable convenience stores.
        attr_reader :confirmation_number
        # The number of calendar days (between 1 and 60) after which Konbini payment instructions will expire. For example, if a PaymentIntent is confirmed with Konbini and `expires_after_days` set to 2 on Monday JST, the instructions will expire on Wednesday 23:59:59 JST.
        attr_reader :expires_after_days
        # The timestamp at which the Konbini payment instructions will expire. Only one of `expires_after_days` or `expires_at` may be set.
        attr_reader :expires_at
        # A product descriptor of up to 22 characters, which will appear to customers at the convenience store.
        attr_reader :product_description
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
        # [Deprecated] This is a legacy parameter that no longer has any function.
        attr_reader :persistent_token
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

      class MbWay < ::Stripe::StripeObject
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

      class NzBankAccount < ::Stripe::StripeObject
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

      class PayByBank < ::Stripe::StripeObject
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
        # The number of seconds (between 10 and 1209600) after which Pix payment will expire.
        attr_reader :expires_after_seconds
        # The timestamp at which the Pix expires.
        attr_reader :expires_at
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

      class Promptpay < ::Stripe::StripeObject
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
        # Preferred language of the SOFORT authorization page that the customer is redirected to.
        attr_reader :preferred_language
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
        # A reference for this payment to be displayed in the Swish app.
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
        # Preferred transaction settlement speed
        attr_reader :preferred_settlement_speed
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
          @inner_class_types = {
            financial_connections: FinancialConnections,
            mandate_options: MandateOptions,
          }
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end

      class WechatPay < ::Stripe::StripeObject
        # The app ID registered with WeChat Pay. Only required when client is ios or android.
        attr_reader :app_id
        # The client type that the end customer will pay from
        attr_reader :client
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

      class Zip < ::Stripe::StripeObject
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
      # Attribute for field blik
      attr_reader :blik
      # Attribute for field boleto
      attr_reader :boleto
      # Attribute for field card
      attr_reader :card
      # Attribute for field card_present
      attr_reader :card_present
      # Attribute for field cashapp
      attr_reader :cashapp
      # Attribute for field crypto
      attr_reader :crypto
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
      # Attribute for field interac_present
      attr_reader :interac_present
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
      # Attribute for field mb_way
      attr_reader :mb_way
      # Attribute for field mobilepay
      attr_reader :mobilepay
      # Attribute for field multibanco
      attr_reader :multibanco
      # Attribute for field naver_pay
      attr_reader :naver_pay
      # Attribute for field nz_bank_account
      attr_reader :nz_bank_account
      # Attribute for field oxxo
      attr_reader :oxxo
      # Attribute for field p24
      attr_reader :p24
      # Attribute for field pay_by_bank
      attr_reader :pay_by_bank
      # Attribute for field payco
      attr_reader :payco
      # Attribute for field paynow
      attr_reader :paynow
      # Attribute for field paypal
      attr_reader :paypal
      # Attribute for field pix
      attr_reader :pix
      # Attribute for field promptpay
      attr_reader :promptpay
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
      # Attribute for field wechat_pay
      attr_reader :wechat_pay
      # Attribute for field zip
      attr_reader :zip

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
          blik: Blik,
          boleto: Boleto,
          card: Card,
          card_present: CardPresent,
          cashapp: Cashapp,
          crypto: Crypto,
          customer_balance: CustomerBalance,
          eps: Eps,
          fpx: Fpx,
          giropay: Giropay,
          grabpay: Grabpay,
          ideal: Ideal,
          interac_present: InteracPresent,
          kakao_pay: KakaoPay,
          klarna: Klarna,
          konbini: Konbini,
          kr_card: KrCard,
          link: Link,
          mb_way: MbWay,
          mobilepay: Mobilepay,
          multibanco: Multibanco,
          naver_pay: NaverPay,
          nz_bank_account: NzBankAccount,
          oxxo: Oxxo,
          p24: P24,
          pay_by_bank: PayByBank,
          payco: Payco,
          paynow: Paynow,
          paypal: Paypal,
          pix: Pix,
          promptpay: Promptpay,
          revolut_pay: RevolutPay,
          samsung_pay: SamsungPay,
          satispay: Satispay,
          sepa_debit: SepaDebit,
          sofort: Sofort,
          swish: Swish,
          twint: Twint,
          us_bank_account: UsBankAccount,
          wechat_pay: WechatPay,
          zip: Zip,
        }
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

    class Processing < ::Stripe::StripeObject
      class Card < ::Stripe::StripeObject
        class CustomerNotification < ::Stripe::StripeObject
          # Whether customer approval has been requested for this payment. For payments greater than INR 15000 or mandate amount, the customer must provide explicit approval of the payment with their bank.
          attr_reader :approval_requested
          # If customer approval is required, they need to provide approval before this time.
          attr_reader :completes_at

          def self.inner_class_types
            @inner_class_types = {}
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end
        # Attribute for field customer_notification
        attr_reader :customer_notification

        def self.inner_class_types
          @inner_class_types = { customer_notification: CustomerNotification }
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end
      # Attribute for field card
      attr_reader :card
      # Type of the payment method for which payment is in `processing` state, one of `card`.
      attr_reader :type

      def self.inner_class_types
        @inner_class_types = { card: Card }
      end

      def self.field_remappings
        @field_remappings = {}
      end
    end

    class Shipping < ::Stripe::StripeObject
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
      # The delivery service that shipped a physical product, such as Fedex, UPS, USPS, etc.
      attr_reader :carrier
      # Recipient name.
      attr_reader :name
      # Recipient phone (including extension).
      attr_reader :phone
      # The tracking number for a physical product, obtained from the delivery service. If multiple tracking numbers were generated for this purchase, please separate them with commas.
      attr_reader :tracking_number

      def self.inner_class_types
        @inner_class_types = { address: Address }
      end

      def self.field_remappings
        @field_remappings = {}
      end
    end

    class TransferData < ::Stripe::StripeObject
      # The amount transferred to the destination account. This transfer will occur automatically after the payment succeeds. If no amount is specified, by default the entire payment amount is transferred to the destination account.
      #  The amount must be less than or equal to the [amount](https://stripe.com/docs/api/payment_intents/object#payment_intent_object-amount), and must be a positive integer
      #  representing how much to transfer in the smallest currency unit (e.g., 100 cents to charge $1.00).
      attr_reader :amount
      # The account (if any) that the payment is attributed to for tax reporting, and where funds from the payment are transferred to after payment success.
      attr_reader :destination

      def self.inner_class_types
        @inner_class_types = {}
      end

      def self.field_remappings
        @field_remappings = {}
      end
    end
    # Amount intended to be collected by this PaymentIntent. A positive integer representing how much to charge in the [smallest currency unit](https://stripe.com/docs/currencies#zero-decimal) (e.g., 100 cents to charge $1.00 or 100 to charge ¥100, a zero-decimal currency). The minimum amount is $0.50 US or [equivalent in charge currency](https://stripe.com/docs/currencies#minimum-and-maximum-charge-amounts). The amount value supports up to eight digits (e.g., a value of 99999999 for a USD charge of $999,999.99).
    attr_reader :amount
    # Amount that can be captured from this PaymentIntent.
    attr_reader :amount_capturable
    # Attribute for field amount_details
    attr_reader :amount_details
    # Amount that this PaymentIntent collects.
    attr_reader :amount_received
    # ID of the Connect application that created the PaymentIntent.
    attr_reader :application
    # The amount of the application fee (if any) that will be requested to be applied to the payment and transferred to the application owner's Stripe account. The amount of the application fee collected will be capped at the total amount captured. For more information, see the PaymentIntents [use case for connected accounts](https://stripe.com/docs/payments/connected-accounts).
    attr_reader :application_fee_amount
    # Settings to configure compatible payment methods from the [Stripe Dashboard](https://dashboard.stripe.com/settings/payment_methods)
    attr_reader :automatic_payment_methods
    # Populated when `status` is `canceled`, this is the time at which the PaymentIntent was canceled. Measured in seconds since the Unix epoch.
    attr_reader :canceled_at
    # Reason for cancellation of this PaymentIntent, either user-provided (`duplicate`, `fraudulent`, `requested_by_customer`, or `abandoned`) or generated by Stripe internally (`failed_invoice`, `void_invoice`, `automatic`, or `expired`).
    attr_reader :cancellation_reason
    # Controls when the funds will be captured from the customer's account.
    attr_reader :capture_method
    # The client secret of this PaymentIntent. Used for client-side retrieval using a publishable key.
    #
    # The client secret can be used to complete a payment from your frontend. It should not be stored, logged, or exposed to anyone other than the customer. Make sure that you have TLS enabled on any page that includes the client secret.
    #
    # Refer to our docs to [accept a payment](https://stripe.com/docs/payments/accept-a-payment?ui=elements) and learn about how `client_secret` should be handled.
    attr_reader :client_secret
    # Describes whether we can confirm this PaymentIntent automatically, or if it requires customer action to confirm the payment.
    attr_reader :confirmation_method
    # Time at which the object was created. Measured in seconds since the Unix epoch.
    attr_reader :created
    # Three-letter [ISO currency code](https://www.iso.org/iso-4217-currency-codes.html), in lowercase. Must be a [supported currency](https://stripe.com/docs/currencies).
    attr_reader :currency
    # ID of the Customer this PaymentIntent belongs to, if one exists.
    #
    # Payment methods attached to other Customers cannot be used with this PaymentIntent.
    #
    # If [setup_future_usage](https://stripe.com/docs/api#payment_intent_object-setup_future_usage) is set and this PaymentIntent's payment method is not `card_present`, then the payment method attaches to the Customer after the PaymentIntent has been confirmed and any required actions from the user are complete. If the payment method is `card_present` and isn't a digital wallet, then a [generated_card](https://docs.stripe.com/api/charges/object#charge_object-payment_method_details-card_present-generated_card) payment method representing the card is created and attached to the Customer instead.
    attr_reader :customer
    # An arbitrary string attached to the object. Often useful for displaying to users.
    attr_reader :description
    # The list of payment method types to exclude from use with this payment.
    attr_reader :excluded_payment_method_types
    # Attribute for field hooks
    attr_reader :hooks
    # Unique identifier for the object.
    attr_reader :id
    # The payment error encountered in the previous PaymentIntent confirmation. It will be cleared if the PaymentIntent is later updated for any reason.
    attr_reader :last_payment_error
    # ID of the latest [Charge object](https://stripe.com/docs/api/charges) created by this PaymentIntent. This property is `null` until PaymentIntent confirmation is attempted.
    attr_reader :latest_charge
    # Has the value `true` if the object exists in live mode or the value `false` if the object exists in test mode.
    attr_reader :livemode
    # Set of [key-value pairs](https://stripe.com/docs/api/metadata) that you can attach to an object. This can be useful for storing additional information about the object in a structured format. Learn more about [storing information in metadata](https://stripe.com/docs/payments/payment-intents/creating-payment-intents#storing-information-in-metadata).
    attr_reader :metadata
    # If present, this property tells you what actions you need to take in order for your customer to fulfill a payment using the provided source.
    attr_reader :next_action
    # String representing the object's type. Objects of the same type share the same value.
    attr_reader :object
    # The account (if any) for which the funds of the PaymentIntent are intended. See the PaymentIntents [use case for connected accounts](https://stripe.com/docs/payments/connected-accounts) for details.
    attr_reader :on_behalf_of
    # Attribute for field payment_details
    attr_reader :payment_details
    # ID of the payment method used in this PaymentIntent.
    attr_reader :payment_method
    # Information about the [payment method configuration](https://stripe.com/docs/api/payment_method_configurations) used for this PaymentIntent.
    attr_reader :payment_method_configuration_details
    # Payment-method-specific configuration for this PaymentIntent.
    attr_reader :payment_method_options
    # The list of payment method types (e.g. card) that this PaymentIntent is allowed to use. A comprehensive list of valid payment method types can be found [here](https://docs.stripe.com/api/payment_methods/object#payment_method_object-type).
    attr_reader :payment_method_types
    # Attribute for field presentment_details
    attr_reader :presentment_details
    # If present, this property tells you about the processing state of the payment.
    attr_reader :processing
    # Email address that the receipt for the resulting payment will be sent to. If `receipt_email` is specified for a payment in live mode, a receipt will be sent regardless of your [email settings](https://dashboard.stripe.com/account/emails).
    attr_reader :receipt_email
    # ID of the review associated with this PaymentIntent, if any.
    attr_reader :review
    # Indicates that you intend to make future payments with this PaymentIntent's payment method.
    #
    # If you provide a Customer with the PaymentIntent, you can use this parameter to [attach the payment method](/payments/save-during-payment) to the Customer after the PaymentIntent is confirmed and the customer completes any required actions. If you don't provide a Customer, you can still [attach](/api/payment_methods/attach) the payment method to a Customer after the transaction completes.
    #
    # If the payment method is `card_present` and isn't a digital wallet, Stripe creates and attaches a [generated_card](/api/charges/object#charge_object-payment_method_details-card_present-generated_card) payment method representing the card to the Customer instead.
    #
    # When processing card payments, Stripe uses `setup_future_usage` to help you comply with regional legislation and network rules, such as [SCA](/strong-customer-authentication).
    attr_reader :setup_future_usage
    # Shipping information for this PaymentIntent.
    attr_reader :shipping
    # This is a legacy field that will be removed in the future. It is the ID of the Source object that is associated with this PaymentIntent, if one was supplied.
    attr_reader :source
    # Text that appears on the customer's statement as the statement descriptor for a non-card charge. This value overrides the account's default statement descriptor. For information about requirements, including the 22-character limit, see [the Statement Descriptor docs](https://docs.stripe.com/get-started/account/statement-descriptors).
    #
    # Setting this value for a card charge returns an error. For card charges, set the [statement_descriptor_suffix](https://docs.stripe.com/get-started/account/statement-descriptors#dynamic) instead.
    attr_reader :statement_descriptor
    # Provides information about a card charge. Concatenated to the account's [statement descriptor prefix](https://docs.stripe.com/get-started/account/statement-descriptors#static) to form the complete statement descriptor that appears on the customer's statement.
    attr_reader :statement_descriptor_suffix
    # Status of this PaymentIntent, one of `requires_payment_method`, `requires_confirmation`, `requires_action`, `processing`, `requires_capture`, `canceled`, or `succeeded`. Read more about each PaymentIntent [status](https://stripe.com/docs/payments/intents#intent-statuses).
    attr_reader :status
    # The data that automatically creates a Transfer after the payment finalizes. Learn more about the [use case for connected accounts](https://stripe.com/docs/payments/connected-accounts).
    attr_reader :transfer_data
    # A string that identifies the resulting payment as part of a group. Learn more about the [use case for connected accounts](https://stripe.com/docs/connect/separate-charges-and-transfers).
    attr_reader :transfer_group

    # Manually reconcile the remaining amount for a customer_balance PaymentIntent.
    def apply_customer_balance(params = {}, opts = {})
      request_stripe_object(
        method: :post,
        path: format("/v1/payment_intents/%<intent>s/apply_customer_balance", { intent: CGI.escape(self["id"]) }),
        params: params,
        opts: opts
      )
    end

    # Manually reconcile the remaining amount for a customer_balance PaymentIntent.
    def self.apply_customer_balance(intent, params = {}, opts = {})
      request_stripe_object(
        method: :post,
        path: format("/v1/payment_intents/%<intent>s/apply_customer_balance", { intent: CGI.escape(intent) }),
        params: params,
        opts: opts
      )
    end

    # You can cancel a PaymentIntent object when it's in one of these statuses: requires_payment_method, requires_capture, requires_confirmation, requires_action or, [in rare cases](https://docs.stripe.com/docs/payments/intents), processing.
    #
    # After it's canceled, no additional charges are made by the PaymentIntent and any operations on the PaymentIntent fail with an error. For PaymentIntents with a status of requires_capture, the remaining amount_capturable is automatically refunded.
    #
    # You can't cancel the PaymentIntent for a Checkout Session. [Expire the Checkout Session](https://docs.stripe.com/docs/api/checkout/sessions/expire) instead.
    def cancel(params = {}, opts = {})
      request_stripe_object(
        method: :post,
        path: format("/v1/payment_intents/%<intent>s/cancel", { intent: CGI.escape(self["id"]) }),
        params: params,
        opts: opts
      )
    end

    # You can cancel a PaymentIntent object when it's in one of these statuses: requires_payment_method, requires_capture, requires_confirmation, requires_action or, [in rare cases](https://docs.stripe.com/docs/payments/intents), processing.
    #
    # After it's canceled, no additional charges are made by the PaymentIntent and any operations on the PaymentIntent fail with an error. For PaymentIntents with a status of requires_capture, the remaining amount_capturable is automatically refunded.
    #
    # You can't cancel the PaymentIntent for a Checkout Session. [Expire the Checkout Session](https://docs.stripe.com/docs/api/checkout/sessions/expire) instead.
    def self.cancel(intent, params = {}, opts = {})
      request_stripe_object(
        method: :post,
        path: format("/v1/payment_intents/%<intent>s/cancel", { intent: CGI.escape(intent) }),
        params: params,
        opts: opts
      )
    end

    # Capture the funds of an existing uncaptured PaymentIntent when its status is requires_capture.
    #
    # Uncaptured PaymentIntents are cancelled a set number of days (7 by default) after their creation.
    #
    # Learn more about [separate authorization and capture](https://docs.stripe.com/docs/payments/capture-later).
    def capture(params = {}, opts = {})
      request_stripe_object(
        method: :post,
        path: format("/v1/payment_intents/%<intent>s/capture", { intent: CGI.escape(self["id"]) }),
        params: params,
        opts: opts
      )
    end

    # Capture the funds of an existing uncaptured PaymentIntent when its status is requires_capture.
    #
    # Uncaptured PaymentIntents are cancelled a set number of days (7 by default) after their creation.
    #
    # Learn more about [separate authorization and capture](https://docs.stripe.com/docs/payments/capture-later).
    def self.capture(intent, params = {}, opts = {})
      request_stripe_object(
        method: :post,
        path: format("/v1/payment_intents/%<intent>s/capture", { intent: CGI.escape(intent) }),
        params: params,
        opts: opts
      )
    end

    # Confirm that your customer intends to pay with current or provided
    # payment method. Upon confirmation, the PaymentIntent will attempt to initiate
    # a payment.
    #
    # If the selected payment method requires additional authentication steps, the
    # PaymentIntent will transition to the requires_action status and
    # suggest additional actions via next_action. If payment fails,
    # the PaymentIntent transitions to the requires_payment_method status or the
    # canceled status if the confirmation limit is reached. If
    # payment succeeds, the PaymentIntent will transition to the succeeded
    # status (or requires_capture, if capture_method is set to manual).
    #
    # If the confirmation_method is automatic, payment may be attempted
    # using our [client SDKs](https://docs.stripe.com/docs/stripe-js/reference#stripe-handle-card-payment)
    # and the PaymentIntent's [client_secret](https://docs.stripe.com/api#payment_intent_object-client_secret).
    # After next_actions are handled by the client, no additional
    # confirmation is required to complete the payment.
    #
    # If the confirmation_method is manual, all payment attempts must be
    # initiated using a secret key.
    #
    # If any actions are required for the payment, the PaymentIntent will
    # return to the requires_confirmation state
    # after those actions are completed. Your server needs to then
    # explicitly re-confirm the PaymentIntent to initiate the next payment
    # attempt.
    #
    # There is a variable upper limit on how many times a PaymentIntent can be confirmed.
    # After this limit is reached, any further calls to this endpoint will
    # transition the PaymentIntent to the canceled state.
    def confirm(params = {}, opts = {})
      request_stripe_object(
        method: :post,
        path: format("/v1/payment_intents/%<intent>s/confirm", { intent: CGI.escape(self["id"]) }),
        params: params,
        opts: opts
      )
    end

    # Confirm that your customer intends to pay with current or provided
    # payment method. Upon confirmation, the PaymentIntent will attempt to initiate
    # a payment.
    #
    # If the selected payment method requires additional authentication steps, the
    # PaymentIntent will transition to the requires_action status and
    # suggest additional actions via next_action. If payment fails,
    # the PaymentIntent transitions to the requires_payment_method status or the
    # canceled status if the confirmation limit is reached. If
    # payment succeeds, the PaymentIntent will transition to the succeeded
    # status (or requires_capture, if capture_method is set to manual).
    #
    # If the confirmation_method is automatic, payment may be attempted
    # using our [client SDKs](https://docs.stripe.com/docs/stripe-js/reference#stripe-handle-card-payment)
    # and the PaymentIntent's [client_secret](https://docs.stripe.com/api#payment_intent_object-client_secret).
    # After next_actions are handled by the client, no additional
    # confirmation is required to complete the payment.
    #
    # If the confirmation_method is manual, all payment attempts must be
    # initiated using a secret key.
    #
    # If any actions are required for the payment, the PaymentIntent will
    # return to the requires_confirmation state
    # after those actions are completed. Your server needs to then
    # explicitly re-confirm the PaymentIntent to initiate the next payment
    # attempt.
    #
    # There is a variable upper limit on how many times a PaymentIntent can be confirmed.
    # After this limit is reached, any further calls to this endpoint will
    # transition the PaymentIntent to the canceled state.
    def self.confirm(intent, params = {}, opts = {})
      request_stripe_object(
        method: :post,
        path: format("/v1/payment_intents/%<intent>s/confirm", { intent: CGI.escape(intent) }),
        params: params,
        opts: opts
      )
    end

    # Creates a PaymentIntent object.
    #
    # After the PaymentIntent is created, attach a payment method and [confirm](https://docs.stripe.com/docs/api/payment_intents/confirm)
    # to continue the payment. Learn more about <a href="/docs/payments/payment-intents">the available payment flows
    # with the Payment Intents API.
    #
    # When you use confirm=true during creation, it's equivalent to creating
    # and confirming the PaymentIntent in the same call. You can use any parameters
    # available in the [confirm API](https://docs.stripe.com/docs/api/payment_intents/confirm) when you supply
    # confirm=true.
    def self.create(params = {}, opts = {})
      request_stripe_object(method: :post, path: "/v1/payment_intents", params: params, opts: opts)
    end

    # Perform an incremental authorization on an eligible
    # [PaymentIntent](https://docs.stripe.com/docs/api/payment_intents/object). To be eligible, the
    # PaymentIntent's status must be requires_capture and
    # [incremental_authorization_supported](https://docs.stripe.com/docs/api/charges/object#charge_object-payment_method_details-card_present-incremental_authorization_supported)
    # must be true.
    #
    # Incremental authorizations attempt to increase the authorized amount on
    # your customer's card to the new, higher amount provided. Similar to the
    # initial authorization, incremental authorizations can be declined. A
    # single PaymentIntent can call this endpoint multiple times to further
    # increase the authorized amount.
    #
    # If the incremental authorization succeeds, the PaymentIntent object
    # returns with the updated
    # [amount](https://docs.stripe.com/docs/api/payment_intents/object#payment_intent_object-amount).
    # If the incremental authorization fails, a
    # [card_declined](https://docs.stripe.com/docs/error-codes#card-declined) error returns, and no other
    # fields on the PaymentIntent or Charge update. The PaymentIntent
    # object remains capturable for the previously authorized amount.
    #
    # Each PaymentIntent can have a maximum of 10 incremental authorization attempts, including declines.
    # After it's captured, a PaymentIntent can no longer be incremented.
    #
    # Learn more about [incremental authorizations](https://docs.stripe.com/docs/terminal/features/incremental-authorizations).
    def increment_authorization(params = {}, opts = {})
      request_stripe_object(
        method: :post,
        path: format("/v1/payment_intents/%<intent>s/increment_authorization", { intent: CGI.escape(self["id"]) }),
        params: params,
        opts: opts
      )
    end

    # Perform an incremental authorization on an eligible
    # [PaymentIntent](https://docs.stripe.com/docs/api/payment_intents/object). To be eligible, the
    # PaymentIntent's status must be requires_capture and
    # [incremental_authorization_supported](https://docs.stripe.com/docs/api/charges/object#charge_object-payment_method_details-card_present-incremental_authorization_supported)
    # must be true.
    #
    # Incremental authorizations attempt to increase the authorized amount on
    # your customer's card to the new, higher amount provided. Similar to the
    # initial authorization, incremental authorizations can be declined. A
    # single PaymentIntent can call this endpoint multiple times to further
    # increase the authorized amount.
    #
    # If the incremental authorization succeeds, the PaymentIntent object
    # returns with the updated
    # [amount](https://docs.stripe.com/docs/api/payment_intents/object#payment_intent_object-amount).
    # If the incremental authorization fails, a
    # [card_declined](https://docs.stripe.com/docs/error-codes#card-declined) error returns, and no other
    # fields on the PaymentIntent or Charge update. The PaymentIntent
    # object remains capturable for the previously authorized amount.
    #
    # Each PaymentIntent can have a maximum of 10 incremental authorization attempts, including declines.
    # After it's captured, a PaymentIntent can no longer be incremented.
    #
    # Learn more about [incremental authorizations](https://docs.stripe.com/docs/terminal/features/incremental-authorizations).
    def self.increment_authorization(intent, params = {}, opts = {})
      request_stripe_object(
        method: :post,
        path: format("/v1/payment_intents/%<intent>s/increment_authorization", { intent: CGI.escape(intent) }),
        params: params,
        opts: opts
      )
    end

    # Returns a list of PaymentIntents.
    def self.list(params = {}, opts = {})
      request_stripe_object(method: :get, path: "/v1/payment_intents", params: params, opts: opts)
    end

    def self.search(params = {}, opts = {})
      request_stripe_object(
        method: :get,
        path: "/v1/payment_intents/search",
        params: params,
        opts: opts
      )
    end

    def self.search_auto_paging_each(params = {}, opts = {}, &blk)
      search(params, opts).auto_paging_each(&blk)
    end

    # Updates properties on a PaymentIntent object without confirming.
    #
    # Depending on which properties you update, you might need to confirm the
    # PaymentIntent again. For example, updating the payment_method
    # always requires you to confirm the PaymentIntent again. If you prefer to
    # update and confirm at the same time, we recommend updating properties through
    # the [confirm API](https://docs.stripe.com/docs/api/payment_intents/confirm) instead.
    def self.update(intent, params = {}, opts = {})
      request_stripe_object(
        method: :post,
        path: format("/v1/payment_intents/%<intent>s", { intent: CGI.escape(intent) }),
        params: params,
        opts: opts
      )
    end

    # Verifies microdeposits on a PaymentIntent object.
    def verify_microdeposits(params = {}, opts = {})
      request_stripe_object(
        method: :post,
        path: format("/v1/payment_intents/%<intent>s/verify_microdeposits", { intent: CGI.escape(self["id"]) }),
        params: params,
        opts: opts
      )
    end

    # Verifies microdeposits on a PaymentIntent object.
    def self.verify_microdeposits(intent, params = {}, opts = {})
      request_stripe_object(
        method: :post,
        path: format("/v1/payment_intents/%<intent>s/verify_microdeposits", { intent: CGI.escape(intent) }),
        params: params,
        opts: opts
      )
    end

    def self.inner_class_types
      @inner_class_types = {
        amount_details: AmountDetails,
        automatic_payment_methods: AutomaticPaymentMethods,
        hooks: Hooks,
        last_payment_error: LastPaymentError,
        next_action: NextAction,
        payment_details: PaymentDetails,
        payment_method_configuration_details: PaymentMethodConfigurationDetails,
        payment_method_options: PaymentMethodOptions,
        presentment_details: PresentmentDetails,
        processing: Processing,
        shipping: Shipping,
        transfer_data: TransferData,
      }
    end

    def self.field_remappings
      @field_remappings = {}
    end
  end
end
