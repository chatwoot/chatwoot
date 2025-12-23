# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  class InvoiceUpdateParams < ::Stripe::RequestParams
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
      # Whether Stripe automatically computes tax on this invoice. Note that incompatible invoice items (invoice items with manually specified [tax rates](https://stripe.com/docs/api/tax_rates), negative amounts, or `tax_behavior=unspecified`) cannot be added to automatic tax invoices.
      attr_accessor :enabled
      # The account that's liable for tax. If set, the business address and tax registrations required to perform the tax calculation are loaded from this account. The tax transaction is returned in the report of the connected account.
      attr_accessor :liability

      def initialize(enabled: nil, liability: nil)
        @enabled = enabled
        @liability = liability
      end
    end

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

    class Discount < ::Stripe::RequestParams
      # ID of the coupon to create a new discount for.
      attr_accessor :coupon
      # ID of an existing discount on the object (or one of its ancestors) to reuse.
      attr_accessor :discount
      # ID of the promotion code to create a new discount for.
      attr_accessor :promotion_code

      def initialize(coupon: nil, discount: nil, promotion_code: nil)
        @coupon = coupon
        @discount = discount
        @promotion_code = promotion_code
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

    class PaymentSettings < ::Stripe::RequestParams
      class PaymentMethodOptions < ::Stripe::RequestParams
        class AcssDebit < ::Stripe::RequestParams
          class MandateOptions < ::Stripe::RequestParams
            # Transaction type of the mandate.
            attr_accessor :transaction_type

            def initialize(transaction_type: nil)
              @transaction_type = transaction_type
            end
          end
          # Additional fields for Mandate creation
          attr_accessor :mandate_options
          # Verification method for the intent
          attr_accessor :verification_method

          def initialize(mandate_options: nil, verification_method: nil)
            @mandate_options = mandate_options
            @verification_method = verification_method
          end
        end

        class Bancontact < ::Stripe::RequestParams
          # Preferred language of the Bancontact authorization page that the customer is redirected to.
          attr_accessor :preferred_language

          def initialize(preferred_language: nil)
            @preferred_language = preferred_language
          end
        end

        class Card < ::Stripe::RequestParams
          class Installments < ::Stripe::RequestParams
            class Plan < ::Stripe::RequestParams
              # For `fixed_count` installment plans, this is required. It represents the number of installment payments your customer will make to their credit card.
              attr_accessor :count
              # For `fixed_count` installment plans, this is required. It represents the interval between installment payments your customer will make to their credit card.
              # One of `month`.
              attr_accessor :interval
              # Type of installment plan, one of `fixed_count`, `bonus`, or `revolving`.
              attr_accessor :type

              def initialize(count: nil, interval: nil, type: nil)
                @count = count
                @interval = interval
                @type = type
              end
            end
            # Setting to true enables installments for this invoice.
            # Setting to false will prevent any selected plan from applying to a payment.
            attr_accessor :enabled
            # The selected installment plan to use for this invoice.
            attr_accessor :plan

            def initialize(enabled: nil, plan: nil)
              @enabled = enabled
              @plan = plan
            end
          end
          # Installment configuration for payments attempted on this invoice.
          #
          # For more information, see the [installments integration guide](https://stripe.com/docs/payments/installments).
          attr_accessor :installments
          # We strongly recommend that you rely on our SCA Engine to automatically prompt your customers for authentication based on risk level and [other requirements](https://stripe.com/docs/strong-customer-authentication). However, if you wish to request 3D Secure based on logic from your own fraud engine, provide this option. Read our guide on [manually requesting 3D Secure](https://stripe.com/docs/payments/3d-secure/authentication-flow#manual-three-ds) for more information on how this configuration interacts with Radar and our SCA Engine.
          attr_accessor :request_three_d_secure

          def initialize(installments: nil, request_three_d_secure: nil)
            @installments = installments
            @request_three_d_secure = request_three_d_secure
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
            # The bank transfer type that can be used for funding. Permitted values include: `eu_bank_transfer`, `gb_bank_transfer`, `jp_bank_transfer`, `mx_bank_transfer`, or `us_bank_transfer`.
            attr_accessor :type

            def initialize(eu_bank_transfer: nil, type: nil)
              @eu_bank_transfer = eu_bank_transfer
              @type = type
            end
          end
          # Configuration for the bank transfer funding type, if the `funding_type` is set to `bank_transfer`.
          attr_accessor :bank_transfer
          # The funding method type to be used when there are not enough funds in the customer balance. Permitted values include: `bank_transfer`.
          attr_accessor :funding_type

          def initialize(bank_transfer: nil, funding_type: nil)
            @bank_transfer = bank_transfer
            @funding_type = funding_type
          end
        end

        class Konbini < ::Stripe::RequestParams; end
        class SepaDebit < ::Stripe::RequestParams; end

        class UsBankAccount < ::Stripe::RequestParams
          class FinancialConnections < ::Stripe::RequestParams
            class Filters < ::Stripe::RequestParams
              # The account subcategories to use to filter for selectable accounts. Valid subcategories are `checking` and `savings`.
              attr_accessor :account_subcategories

              def initialize(account_subcategories: nil)
                @account_subcategories = account_subcategories
              end
            end
            # Provide filters for the linked accounts that the customer can select for the payment method.
            attr_accessor :filters
            # The list of permissions to request. If this parameter is passed, the `payment_method` permission must be included. Valid permissions include: `balances`, `ownership`, `payment_method`, and `transactions`.
            attr_accessor :permissions
            # List of data features that you would like to retrieve upon account creation.
            attr_accessor :prefetch

            def initialize(filters: nil, permissions: nil, prefetch: nil)
              @filters = filters
              @permissions = permissions
              @prefetch = prefetch
            end
          end
          # Additional fields for Financial Connections Session creation
          attr_accessor :financial_connections
          # Verification method for the intent
          attr_accessor :verification_method

          def initialize(financial_connections: nil, verification_method: nil)
            @financial_connections = financial_connections
            @verification_method = verification_method
          end
        end
        # If paying by `acss_debit`, this sub-hash contains details about the Canadian pre-authorized debit payment method options to pass to the invoice’s PaymentIntent.
        attr_accessor :acss_debit
        # If paying by `bancontact`, this sub-hash contains details about the Bancontact payment method options to pass to the invoice’s PaymentIntent.
        attr_accessor :bancontact
        # If paying by `card`, this sub-hash contains details about the Card payment method options to pass to the invoice’s PaymentIntent.
        attr_accessor :card
        # If paying by `customer_balance`, this sub-hash contains details about the Bank transfer payment method options to pass to the invoice’s PaymentIntent.
        attr_accessor :customer_balance
        # If paying by `konbini`, this sub-hash contains details about the Konbini payment method options to pass to the invoice’s PaymentIntent.
        attr_accessor :konbini
        # If paying by `sepa_debit`, this sub-hash contains details about the SEPA Direct Debit payment method options to pass to the invoice’s PaymentIntent.
        attr_accessor :sepa_debit
        # If paying by `us_bank_account`, this sub-hash contains details about the ACH direct debit payment method options to pass to the invoice’s PaymentIntent.
        attr_accessor :us_bank_account

        def initialize(
          acss_debit: nil,
          bancontact: nil,
          card: nil,
          customer_balance: nil,
          konbini: nil,
          sepa_debit: nil,
          us_bank_account: nil
        )
          @acss_debit = acss_debit
          @bancontact = bancontact
          @card = card
          @customer_balance = customer_balance
          @konbini = konbini
          @sepa_debit = sepa_debit
          @us_bank_account = us_bank_account
        end
      end
      # ID of the mandate to be used for this invoice. It must correspond to the payment method used to pay the invoice, including the invoice's default_payment_method or default_source, if set.
      attr_accessor :default_mandate
      # Payment-method-specific configuration to provide to the invoice’s PaymentIntent.
      attr_accessor :payment_method_options
      # The list of payment method types (e.g. card) to provide to the invoice’s PaymentIntent. If not set, Stripe attempts to automatically determine the types to use by looking at the invoice’s default payment method, the subscription’s default payment method, the customer’s default payment method, and your [invoice template settings](https://dashboard.stripe.com/settings/billing/invoice).
      attr_accessor :payment_method_types

      def initialize(default_mandate: nil, payment_method_options: nil, payment_method_types: nil)
        @default_mandate = default_mandate
        @payment_method_options = payment_method_options
        @payment_method_types = payment_method_types
      end
    end

    class Rendering < ::Stripe::RequestParams
      class Pdf < ::Stripe::RequestParams
        # Page size for invoice PDF. Can be set to `a4`, `letter`, or `auto`.
        #  If set to `auto`, invoice PDF page size defaults to `a4` for customers with
        #  Japanese locale and `letter` for customers with other locales.
        attr_accessor :page_size

        def initialize(page_size: nil)
          @page_size = page_size
        end
      end
      # How line-item prices and amounts will be displayed with respect to tax on invoice PDFs. One of `exclude_tax` or `include_inclusive_tax`. `include_inclusive_tax` will include inclusive tax (and exclude exclusive tax) in invoice PDF amounts. `exclude_tax` will exclude all tax (inclusive and exclusive alike) from invoice PDF amounts.
      attr_accessor :amount_tax_display
      # Invoice pdf rendering options
      attr_accessor :pdf
      # ID of the invoice rendering template to use for this invoice.
      attr_accessor :template
      # The specific version of invoice rendering template to use for this invoice.
      attr_accessor :template_version

      def initialize(amount_tax_display: nil, pdf: nil, template: nil, template_version: nil)
        @amount_tax_display = amount_tax_display
        @pdf = pdf
        @template = template
        @template_version = template_version
      end
    end

    class ShippingCost < ::Stripe::RequestParams
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
      # The ID of the shipping rate to use for this order.
      attr_accessor :shipping_rate
      # Parameters to create a new ad-hoc shipping rate for this order.
      attr_accessor :shipping_rate_data

      def initialize(shipping_rate: nil, shipping_rate_data: nil)
        @shipping_rate = shipping_rate
        @shipping_rate_data = shipping_rate_data
      end
    end

    class ShippingDetails < ::Stripe::RequestParams
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
      # Shipping address
      attr_accessor :address
      # Recipient name.
      attr_accessor :name
      # Recipient phone (including extension)
      attr_accessor :phone

      def initialize(address: nil, name: nil, phone: nil)
        @address = address
        @name = name
        @phone = phone
      end
    end

    class TransferData < ::Stripe::RequestParams
      # The amount that will be transferred automatically when the invoice is paid. If no amount is set, the full amount is transferred.
      attr_accessor :amount
      # ID of an existing, connected Stripe account.
      attr_accessor :destination

      def initialize(amount: nil, destination: nil)
        @amount = amount
        @destination = destination
      end
    end
    # The account tax IDs associated with the invoice. Only editable when the invoice is a draft.
    attr_accessor :account_tax_ids
    # A fee in cents (or local equivalent) that will be applied to the invoice and transferred to the application owner's Stripe account. The request must be made with an OAuth key or the Stripe-Account header in order to take an application fee. For more information, see the application fees [documentation](https://stripe.com/docs/billing/invoices/connect#collecting-fees).
    attr_accessor :application_fee_amount
    # Controls whether Stripe performs [automatic collection](https://stripe.com/docs/invoicing/integration/automatic-advancement-collection) of the invoice.
    attr_accessor :auto_advance
    # Settings for automatic tax lookup for this invoice.
    attr_accessor :automatic_tax
    # The time when this invoice should be scheduled to finalize (up to 5 years in the future). The invoice is finalized at this time if it's still in draft state. To turn off automatic finalization, set `auto_advance` to false.
    attr_accessor :automatically_finalizes_at
    # Either `charge_automatically` or `send_invoice`. This field can be updated only on `draft` invoices.
    attr_accessor :collection_method
    # A list of up to 4 custom fields to be displayed on the invoice. If a value for `custom_fields` is specified, the list specified will replace the existing custom field list on this invoice. Pass an empty string to remove previously-defined fields.
    attr_accessor :custom_fields
    # The number of days from which the invoice is created until it is due. Only valid for invoices where `collection_method=send_invoice`. This field can only be updated on `draft` invoices.
    attr_accessor :days_until_due
    # ID of the default payment method for the invoice. It must belong to the customer associated with the invoice. If not set, defaults to the subscription's default payment method, if any, or to the default payment method in the customer's invoice settings.
    attr_accessor :default_payment_method
    # ID of the default payment source for the invoice. It must belong to the customer associated with the invoice and be in a chargeable state. If not set, defaults to the subscription's default source, if any, or to the customer's default source.
    attr_accessor :default_source
    # The tax rates that will apply to any line item that does not have `tax_rates` set. Pass an empty string to remove previously-defined tax rates.
    attr_accessor :default_tax_rates
    # An arbitrary string attached to the object. Often useful for displaying to users. Referenced as 'memo' in the Dashboard.
    attr_accessor :description
    # The discounts that will apply to the invoice. Pass an empty string to remove previously-defined discounts.
    attr_accessor :discounts
    # The date on which payment for this invoice is due. Only valid for invoices where `collection_method=send_invoice`. This field can only be updated on `draft` invoices.
    attr_accessor :due_date
    # The date when this invoice is in effect. Same as `finalized_at` unless overwritten. When defined, this value replaces the system-generated 'Date of issue' printed on the invoice PDF and receipt.
    attr_accessor :effective_at
    # Specifies which fields in the response should be expanded.
    attr_accessor :expand
    # Footer to be displayed on the invoice.
    attr_accessor :footer
    # The connected account that issues the invoice. The invoice is presented with the branding and support information of the specified account.
    attr_accessor :issuer
    # Set of [key-value pairs](https://stripe.com/docs/api/metadata) that you can attach to an object. This can be useful for storing additional information about the object in a structured format. Individual keys can be unset by posting an empty value to them. All keys can be unset by posting an empty value to `metadata`.
    attr_accessor :metadata
    # Set the number for this invoice. If no number is present then a number will be assigned automatically when the invoice is finalized. In many markets, regulations require invoices to be unique, sequential and / or gapless. You are responsible for ensuring this is true across all your different invoicing systems in the event that you edit the invoice number using our API. If you use only Stripe for your invoices and do not change invoice numbers, Stripe handles this aspect of compliance for you automatically.
    attr_accessor :number
    # The account (if any) for which the funds of the invoice payment are intended. If set, the invoice will be presented with the branding and support information of the specified account. See the [Invoices with Connect](https://stripe.com/docs/billing/invoices/connect) documentation for details.
    attr_accessor :on_behalf_of
    # Configuration settings for the PaymentIntent that is generated when the invoice is finalized.
    attr_accessor :payment_settings
    # The rendering-related settings that control how the invoice is displayed on customer-facing surfaces such as PDF and Hosted Invoice Page.
    attr_accessor :rendering
    # Settings for the cost of shipping for this invoice.
    attr_accessor :shipping_cost
    # Shipping details for the invoice. The Invoice PDF will use the `shipping_details` value if it is set, otherwise the PDF will render the shipping address from the customer.
    attr_accessor :shipping_details
    # Extra information about a charge for the customer's credit card statement. It must contain at least one letter. If not specified and this invoice is part of a subscription, the default `statement_descriptor` will be set to the first subscription item's product's `statement_descriptor`.
    attr_accessor :statement_descriptor
    # If specified, the funds from the invoice will be transferred to the destination and the ID of the resulting transfer will be found on the invoice's charge. This will be unset if you POST an empty value.
    attr_accessor :transfer_data

    def initialize(
      account_tax_ids: nil,
      application_fee_amount: nil,
      auto_advance: nil,
      automatic_tax: nil,
      automatically_finalizes_at: nil,
      collection_method: nil,
      custom_fields: nil,
      days_until_due: nil,
      default_payment_method: nil,
      default_source: nil,
      default_tax_rates: nil,
      description: nil,
      discounts: nil,
      due_date: nil,
      effective_at: nil,
      expand: nil,
      footer: nil,
      issuer: nil,
      metadata: nil,
      number: nil,
      on_behalf_of: nil,
      payment_settings: nil,
      rendering: nil,
      shipping_cost: nil,
      shipping_details: nil,
      statement_descriptor: nil,
      transfer_data: nil
    )
      @account_tax_ids = account_tax_ids
      @application_fee_amount = application_fee_amount
      @auto_advance = auto_advance
      @automatic_tax = automatic_tax
      @automatically_finalizes_at = automatically_finalizes_at
      @collection_method = collection_method
      @custom_fields = custom_fields
      @days_until_due = days_until_due
      @default_payment_method = default_payment_method
      @default_source = default_source
      @default_tax_rates = default_tax_rates
      @description = description
      @discounts = discounts
      @due_date = due_date
      @effective_at = effective_at
      @expand = expand
      @footer = footer
      @issuer = issuer
      @metadata = metadata
      @number = number
      @on_behalf_of = on_behalf_of
      @payment_settings = payment_settings
      @rendering = rendering
      @shipping_cost = shipping_cost
      @shipping_details = shipping_details
      @statement_descriptor = statement_descriptor
      @transfer_data = transfer_data
    end
  end
end
