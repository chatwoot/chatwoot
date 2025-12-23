# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  class SubscriptionCreateParams < ::Stripe::RequestParams
    class AddInvoiceItem < ::Stripe::RequestParams
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

      class Period < ::Stripe::RequestParams
        class End < ::Stripe::RequestParams
          # A precise Unix timestamp for the end of the invoice item period. Must be greater than or equal to `period.start`.
          attr_accessor :timestamp
          # Select how to calculate the end of the invoice item period.
          attr_accessor :type

          def initialize(timestamp: nil, type: nil)
            @timestamp = timestamp
            @type = type
          end
        end

        class Start < ::Stripe::RequestParams
          # A precise Unix timestamp for the start of the invoice item period. Must be less than or equal to `period.end`.
          attr_accessor :timestamp
          # Select how to calculate the start of the invoice item period.
          attr_accessor :type

          def initialize(timestamp: nil, type: nil)
            @timestamp = timestamp
            @type = type
          end
        end
        # End of the invoice item period.
        attr_accessor :end
        # Start of the invoice item period.
        attr_accessor :start

        def initialize(end_: nil, start: nil)
          @end = end_
          @start = start
        end
      end

      class PriceData < ::Stripe::RequestParams
        # Three-letter [ISO currency code](https://www.iso.org/iso-4217-currency-codes.html), in lowercase. Must be a [supported currency](https://stripe.com/docs/currencies).
        attr_accessor :currency
        # The ID of the [Product](https://docs.stripe.com/api/products) that this [Price](https://docs.stripe.com/api/prices) will belong to.
        attr_accessor :product
        # Only required if a [default tax behavior](https://stripe.com/docs/tax/products-prices-tax-categories-tax-behavior#setting-a-default-tax-behavior-(recommended)) was not provided in the Stripe Tax settings. Specifies whether the price is considered inclusive of taxes or exclusive of taxes. One of `inclusive`, `exclusive`, or `unspecified`. Once specified as either `inclusive` or `exclusive`, it cannot be changed.
        attr_accessor :tax_behavior
        # A positive integer in cents (or local equivalent) (or 0 for a free price) representing how much to charge or a negative integer representing the amount to credit to the customer.
        attr_accessor :unit_amount
        # Same as `unit_amount`, but accepts a decimal value in cents (or local equivalent) with at most 12 decimal places. Only one of `unit_amount` and `unit_amount_decimal` can be set.
        attr_accessor :unit_amount_decimal

        def initialize(
          currency: nil,
          product: nil,
          tax_behavior: nil,
          unit_amount: nil,
          unit_amount_decimal: nil
        )
          @currency = currency
          @product = product
          @tax_behavior = tax_behavior
          @unit_amount = unit_amount
          @unit_amount_decimal = unit_amount_decimal
        end
      end
      # The coupons to redeem into discounts for the item.
      attr_accessor :discounts
      # Set of [key-value pairs](https://stripe.com/docs/api/metadata) that you can attach to an object. This can be useful for storing additional information about the object in a structured format. Individual keys can be unset by posting an empty value to them. All keys can be unset by posting an empty value to `metadata`.
      attr_accessor :metadata
      # The period associated with this invoice item. If not set, `period.start.type` defaults to `max_item_period_start` and `period.end.type` defaults to `min_item_period_end`.
      attr_accessor :period
      # The ID of the price object. One of `price` or `price_data` is required.
      attr_accessor :price
      # Data used to generate a new [Price](https://stripe.com/docs/api/prices) object inline. One of `price` or `price_data` is required.
      attr_accessor :price_data
      # Quantity for this item. Defaults to 1.
      attr_accessor :quantity
      # The tax rates which apply to the item. When set, the `default_tax_rates` do not apply to this item.
      attr_accessor :tax_rates

      def initialize(
        discounts: nil,
        metadata: nil,
        period: nil,
        price: nil,
        price_data: nil,
        quantity: nil,
        tax_rates: nil
      )
        @discounts = discounts
        @metadata = metadata
        @period = period
        @price = price
        @price_data = price_data
        @quantity = quantity
        @tax_rates = tax_rates
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
      # Enabled automatic tax calculation which will automatically compute tax rates on all invoices generated by the subscription.
      attr_accessor :enabled
      # The account that's liable for tax. If set, the business address and tax registrations required to perform the tax calculation are loaded from this account. The tax transaction is returned in the report of the connected account.
      attr_accessor :liability

      def initialize(enabled: nil, liability: nil)
        @enabled = enabled
        @liability = liability
      end
    end

    class BillingCycleAnchorConfig < ::Stripe::RequestParams
      # The day of the month the anchor should be. Ranges from 1 to 31.
      attr_accessor :day_of_month
      # The hour of the day the anchor should be. Ranges from 0 to 23.
      attr_accessor :hour
      # The minute of the hour the anchor should be. Ranges from 0 to 59.
      attr_accessor :minute
      # The month to start full cycle periods. Ranges from 1 to 12.
      attr_accessor :month
      # The second of the minute the anchor should be. Ranges from 0 to 59.
      attr_accessor :second

      def initialize(day_of_month: nil, hour: nil, minute: nil, month: nil, second: nil)
        @day_of_month = day_of_month
        @hour = hour
        @minute = minute
        @month = month
        @second = second
      end
    end

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

    class BillingThresholds < ::Stripe::RequestParams
      # Monetary threshold that triggers the subscription to advance to a new billing period
      attr_accessor :amount_gte
      # Indicates if the `billing_cycle_anchor` should be reset when a threshold is reached. If true, `billing_cycle_anchor` will be updated to the date/time the threshold was last reached; otherwise, the value will remain unchanged.
      attr_accessor :reset_billing_cycle_anchor

      def initialize(amount_gte: nil, reset_billing_cycle_anchor: nil)
        @amount_gte = amount_gte
        @reset_billing_cycle_anchor = reset_billing_cycle_anchor
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
      # The account tax IDs associated with the subscription. Will be set on invoices generated by the subscription.
      attr_accessor :account_tax_ids
      # The connected account that issues the invoice. The invoice is presented with the branding and support information of the specified account.
      attr_accessor :issuer

      def initialize(account_tax_ids: nil, issuer: nil)
        @account_tax_ids = account_tax_ids
        @issuer = issuer
      end
    end

    class Item < ::Stripe::RequestParams
      class BillingThresholds < ::Stripe::RequestParams
        # Number of units that meets the billing threshold to advance the subscription to a new billing period (e.g., it takes 10 $5 units to meet a $50 [monetary threshold](https://stripe.com/docs/api/subscriptions/update#update_subscription-billing_thresholds-amount_gte))
        attr_accessor :usage_gte

        def initialize(usage_gte: nil)
          @usage_gte = usage_gte
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

      class PriceData < ::Stripe::RequestParams
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
        # The ID of the [Product](https://docs.stripe.com/api/products) that this [Price](https://docs.stripe.com/api/prices) will belong to.
        attr_accessor :product
        # The recurring components of a price such as `interval` and `interval_count`.
        attr_accessor :recurring
        # Only required if a [default tax behavior](https://stripe.com/docs/tax/products-prices-tax-categories-tax-behavior#setting-a-default-tax-behavior-(recommended)) was not provided in the Stripe Tax settings. Specifies whether the price is considered inclusive of taxes or exclusive of taxes. One of `inclusive`, `exclusive`, or `unspecified`. Once specified as either `inclusive` or `exclusive`, it cannot be changed.
        attr_accessor :tax_behavior
        # A positive integer in cents (or local equivalent) (or 0 for a free price) representing how much to charge.
        attr_accessor :unit_amount
        # Same as `unit_amount`, but accepts a decimal value in cents (or local equivalent) with at most 12 decimal places. Only one of `unit_amount` and `unit_amount_decimal` can be set.
        attr_accessor :unit_amount_decimal

        def initialize(
          currency: nil,
          product: nil,
          recurring: nil,
          tax_behavior: nil,
          unit_amount: nil,
          unit_amount_decimal: nil
        )
          @currency = currency
          @product = product
          @recurring = recurring
          @tax_behavior = tax_behavior
          @unit_amount = unit_amount
          @unit_amount_decimal = unit_amount_decimal
        end
      end
      # Define thresholds at which an invoice will be sent, and the subscription advanced to a new billing period. Pass an empty string to remove previously-defined thresholds.
      attr_accessor :billing_thresholds
      # The coupons to redeem into discounts for the subscription item.
      attr_accessor :discounts
      # Set of [key-value pairs](https://stripe.com/docs/api/metadata) that you can attach to an object. This can be useful for storing additional information about the object in a structured format. Individual keys can be unset by posting an empty value to them. All keys can be unset by posting an empty value to `metadata`.
      attr_accessor :metadata
      # Plan ID for this item, as a string.
      attr_accessor :plan
      # The ID of the price object.
      attr_accessor :price
      # Data used to generate a new [Price](https://stripe.com/docs/api/prices) object inline.
      attr_accessor :price_data
      # Quantity for this item.
      attr_accessor :quantity
      # A list of [Tax Rate](https://stripe.com/docs/api/tax_rates) ids. These Tax Rates will override the [`default_tax_rates`](https://stripe.com/docs/api/subscriptions/create#create_subscription-default_tax_rates) on the Subscription. When updating, pass an empty string to remove previously-defined tax rates.
      attr_accessor :tax_rates

      def initialize(
        billing_thresholds: nil,
        discounts: nil,
        metadata: nil,
        plan: nil,
        price: nil,
        price_data: nil,
        quantity: nil,
        tax_rates: nil
      )
        @billing_thresholds = billing_thresholds
        @discounts = discounts
        @metadata = metadata
        @plan = plan
        @price = price
        @price_data = price_data
        @quantity = quantity
        @tax_rates = tax_rates
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
          class MandateOptions < ::Stripe::RequestParams
            # Amount to be charged for future payments.
            attr_accessor :amount
            # One of `fixed` or `maximum`. If `fixed`, the `amount` param refers to the exact amount to be charged in future payments. If `maximum`, the amount charged can be up to the value passed for the `amount` param.
            attr_accessor :amount_type
            # A description of the mandate or subscription that is meant to be displayed to the customer.
            attr_accessor :description

            def initialize(amount: nil, amount_type: nil, description: nil)
              @amount = amount
              @amount_type = amount_type
              @description = description
            end
          end
          # Configuration options for setting up an eMandate for cards issued in India.
          attr_accessor :mandate_options
          # Selected network to process this Subscription on. Depends on the available networks of the card attached to the Subscription. Can be only set confirm-time.
          attr_accessor :network
          # We strongly recommend that you rely on our SCA Engine to automatically prompt your customers for authentication based on risk level and [other requirements](https://stripe.com/docs/strong-customer-authentication). However, if you wish to request 3D Secure based on logic from your own fraud engine, provide this option. Read our guide on [manually requesting 3D Secure](https://stripe.com/docs/payments/3d-secure/authentication-flow#manual-three-ds) for more information on how this configuration interacts with Radar and our SCA Engine.
          attr_accessor :request_three_d_secure

          def initialize(mandate_options: nil, network: nil, request_three_d_secure: nil)
            @mandate_options = mandate_options
            @network = network
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
        # This sub-hash contains details about the Canadian pre-authorized debit payment method options to pass to the invoice’s PaymentIntent.
        attr_accessor :acss_debit
        # This sub-hash contains details about the Bancontact payment method options to pass to the invoice’s PaymentIntent.
        attr_accessor :bancontact
        # This sub-hash contains details about the Card payment method options to pass to the invoice’s PaymentIntent.
        attr_accessor :card
        # This sub-hash contains details about the Bank transfer payment method options to pass to the invoice’s PaymentIntent.
        attr_accessor :customer_balance
        # This sub-hash contains details about the Konbini payment method options to pass to the invoice’s PaymentIntent.
        attr_accessor :konbini
        # This sub-hash contains details about the SEPA Direct Debit payment method options to pass to the invoice’s PaymentIntent.
        attr_accessor :sepa_debit
        # This sub-hash contains details about the ACH direct debit payment method options to pass to the invoice’s PaymentIntent.
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
      # Payment-method-specific configuration to provide to invoices created by the subscription.
      attr_accessor :payment_method_options
      # The list of payment method types (e.g. card) to provide to the invoice’s PaymentIntent. If not set, Stripe attempts to automatically determine the types to use by looking at the invoice’s default payment method, the subscription’s default payment method, the customer’s default payment method, and your [invoice template settings](https://dashboard.stripe.com/settings/billing/invoice). Should not be specified with payment_method_configuration
      attr_accessor :payment_method_types
      # Configure whether Stripe updates `subscription.default_payment_method` when payment succeeds. Defaults to `off` if unspecified.
      attr_accessor :save_default_payment_method

      def initialize(
        payment_method_options: nil,
        payment_method_types: nil,
        save_default_payment_method: nil
      )
        @payment_method_options = payment_method_options
        @payment_method_types = payment_method_types
        @save_default_payment_method = save_default_payment_method
      end
    end

    class PendingInvoiceItemInterval < ::Stripe::RequestParams
      # Specifies invoicing frequency. Either `day`, `week`, `month` or `year`.
      attr_accessor :interval
      # The number of intervals between invoices. For example, `interval=month` and `interval_count=3` bills every 3 months. Maximum of one year interval allowed (1 year, 12 months, or 52 weeks).
      attr_accessor :interval_count

      def initialize(interval: nil, interval_count: nil)
        @interval = interval
        @interval_count = interval_count
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
    # A list of prices and quantities that will generate invoice items appended to the next invoice for this subscription. You may pass up to 20 items.
    attr_accessor :add_invoice_items
    # A non-negative decimal between 0 and 100, with at most two decimal places. This represents the percentage of the subscription invoice total that will be transferred to the application owner's Stripe account. The request must be made by a platform account on a connected account in order to set an application fee percentage. For more information, see the application fees [documentation](https://stripe.com/docs/connect/subscriptions#collecting-fees-on-subscriptions).
    attr_accessor :application_fee_percent
    # Automatic tax settings for this subscription.
    attr_accessor :automatic_tax
    # A past timestamp to backdate the subscription's start date to. If set, the first invoice will contain line items for the timespan between the start date and the current time. Can be combined with trials and the billing cycle anchor.
    attr_accessor :backdate_start_date
    # A future timestamp in UTC format to anchor the subscription's [billing cycle](https://stripe.com/docs/subscriptions/billing-cycle). The anchor is the reference point that aligns future billing cycle dates. It sets the day of week for `week` intervals, the day of month for `month` and `year` intervals, and the month of year for `year` intervals.
    attr_accessor :billing_cycle_anchor
    # Mutually exclusive with billing_cycle_anchor and only valid with monthly and yearly price intervals. When provided, the billing_cycle_anchor is set to the next occurrence of the day_of_month at the hour, minute, and second UTC.
    attr_accessor :billing_cycle_anchor_config
    # Controls how prorations and invoices for subscriptions are calculated and orchestrated.
    attr_accessor :billing_mode
    # Define thresholds at which an invoice will be sent, and the subscription advanced to a new billing period. When updating, pass an empty string to remove previously-defined thresholds.
    attr_accessor :billing_thresholds
    # A timestamp at which the subscription should cancel. If set to a date before the current period ends, this will cause a proration if prorations have been enabled using `proration_behavior`. If set during a future period, this will always cause a proration for that period.
    attr_accessor :cancel_at
    # Indicate whether this subscription should cancel at the end of the current period (`current_period_end`). Defaults to `false`.
    attr_accessor :cancel_at_period_end
    # Either `charge_automatically`, or `send_invoice`. When charging automatically, Stripe will attempt to pay this subscription at the end of the cycle using the default source attached to the customer. When sending an invoice, Stripe will email your customer an invoice with payment instructions and mark the subscription as `active`. Defaults to `charge_automatically`.
    attr_accessor :collection_method
    # Three-letter [ISO currency code](https://www.iso.org/iso-4217-currency-codes.html), in lowercase. Must be a [supported currency](https://stripe.com/docs/currencies).
    attr_accessor :currency
    # The identifier of the customer to subscribe.
    attr_accessor :customer
    # Number of days a customer has to pay invoices generated by this subscription. Valid only for subscriptions where `collection_method` is set to `send_invoice`.
    attr_accessor :days_until_due
    # ID of the default payment method for the subscription. It must belong to the customer associated with the subscription. This takes precedence over `default_source`. If neither are set, invoices will use the customer's [invoice_settings.default_payment_method](https://stripe.com/docs/api/customers/object#customer_object-invoice_settings-default_payment_method) or [default_source](https://stripe.com/docs/api/customers/object#customer_object-default_source).
    attr_accessor :default_payment_method
    # ID of the default payment source for the subscription. It must belong to the customer associated with the subscription and be in a chargeable state. If `default_payment_method` is also set, `default_payment_method` will take precedence. If neither are set, invoices will use the customer's [invoice_settings.default_payment_method](https://stripe.com/docs/api/customers/object#customer_object-invoice_settings-default_payment_method) or [default_source](https://stripe.com/docs/api/customers/object#customer_object-default_source).
    attr_accessor :default_source
    # The tax rates that will apply to any subscription item that does not have `tax_rates` set. Invoices created will have their `default_tax_rates` populated from the subscription.
    attr_accessor :default_tax_rates
    # The subscription's description, meant to be displayable to the customer. Use this field to optionally store an explanation of the subscription for rendering in Stripe surfaces and certain local payment methods UIs.
    attr_accessor :description
    # The coupons to redeem into discounts for the subscription. If not specified or empty, inherits the discount from the subscription's customer.
    attr_accessor :discounts
    # Specifies which fields in the response should be expanded.
    attr_accessor :expand
    # All invoices will be billed using the specified settings.
    attr_accessor :invoice_settings
    # A list of up to 20 subscription items, each with an attached price.
    attr_accessor :items
    # Set of [key-value pairs](https://stripe.com/docs/api/metadata) that you can attach to an object. This can be useful for storing additional information about the object in a structured format. Individual keys can be unset by posting an empty value to them. All keys can be unset by posting an empty value to `metadata`.
    attr_accessor :metadata
    # Indicates if a customer is on or off-session while an invoice payment is attempted. Defaults to `false` (on-session).
    attr_accessor :off_session
    # The account on behalf of which to charge, for each of the subscription's invoices.
    attr_accessor :on_behalf_of
    # Only applies to subscriptions with `collection_method=charge_automatically`.
    #
    # Use `allow_incomplete` to create Subscriptions with `status=incomplete` if the first invoice can't be paid. Creating Subscriptions with this status allows you to manage scenarios where additional customer actions are needed to pay a subscription's invoice. For example, SCA regulation may require 3DS authentication to complete payment. See the [SCA Migration Guide](https://stripe.com/docs/billing/migration/strong-customer-authentication) for Billing to learn more. This is the default behavior.
    #
    # Use `default_incomplete` to create Subscriptions with `status=incomplete` when the first invoice requires payment, otherwise start as active. Subscriptions transition to `status=active` when successfully confirming the PaymentIntent on the first invoice. This allows simpler management of scenarios where additional customer actions are needed to pay a subscription’s invoice, such as failed payments, [SCA regulation](https://stripe.com/docs/billing/migration/strong-customer-authentication), or collecting a mandate for a bank debit payment method. If the PaymentIntent is not confirmed within 23 hours Subscriptions transition to `status=incomplete_expired`, which is a terminal state.
    #
    # Use `error_if_incomplete` if you want Stripe to return an HTTP 402 status code if a subscription's first invoice can't be paid. For example, if a payment method requires 3DS authentication due to SCA regulation and further customer action is needed, this parameter doesn't create a Subscription and returns an error instead. This was the default behavior for API versions prior to 2019-03-14. See the [changelog](https://stripe.com/docs/upgrades#2019-03-14) to learn more.
    #
    # `pending_if_incomplete` is only used with updates and cannot be passed when creating a Subscription.
    #
    # Subscriptions with `collection_method=send_invoice` are automatically activated regardless of the first Invoice status.
    attr_accessor :payment_behavior
    # Payment settings to pass to invoices created by the subscription.
    attr_accessor :payment_settings
    # Specifies an interval for how often to bill for any pending invoice items. It is analogous to calling [Create an invoice](https://stripe.com/docs/api#create_invoice) for the given subscription at the specified interval.
    attr_accessor :pending_invoice_item_interval
    # Determines how to handle [prorations](https://stripe.com/docs/billing/subscriptions/prorations) resulting from the `billing_cycle_anchor`. If no value is passed, the default is `create_prorations`.
    attr_accessor :proration_behavior
    # If specified, the funds from the subscription's invoices will be transferred to the destination and the ID of the resulting transfers will be found on the resulting charges.
    attr_accessor :transfer_data
    # Unix timestamp representing the end of the trial period the customer will get before being charged for the first time. If set, trial_end will override the default trial period of the plan the customer is being subscribed to. The special value `now` can be provided to end the customer's trial immediately. Can be at most two years from `billing_cycle_anchor`. See [Using trial periods on subscriptions](https://stripe.com/docs/billing/subscriptions/trials) to learn more.
    attr_accessor :trial_end
    # Indicates if a plan's `trial_period_days` should be applied to the subscription. Setting `trial_end` per subscription is preferred, and this defaults to `false`. Setting this flag to `true` together with `trial_end` is not allowed. See [Using trial periods on subscriptions](https://stripe.com/docs/billing/subscriptions/trials) to learn more.
    attr_accessor :trial_from_plan
    # Integer representing the number of trial period days before the customer is charged for the first time. This will always overwrite any trials that might apply via a subscribed plan. See [Using trial periods on subscriptions](https://stripe.com/docs/billing/subscriptions/trials) to learn more.
    attr_accessor :trial_period_days
    # Settings related to subscription trials.
    attr_accessor :trial_settings

    def initialize(
      add_invoice_items: nil,
      application_fee_percent: nil,
      automatic_tax: nil,
      backdate_start_date: nil,
      billing_cycle_anchor: nil,
      billing_cycle_anchor_config: nil,
      billing_mode: nil,
      billing_thresholds: nil,
      cancel_at: nil,
      cancel_at_period_end: nil,
      collection_method: nil,
      currency: nil,
      customer: nil,
      days_until_due: nil,
      default_payment_method: nil,
      default_source: nil,
      default_tax_rates: nil,
      description: nil,
      discounts: nil,
      expand: nil,
      invoice_settings: nil,
      items: nil,
      metadata: nil,
      off_session: nil,
      on_behalf_of: nil,
      payment_behavior: nil,
      payment_settings: nil,
      pending_invoice_item_interval: nil,
      proration_behavior: nil,
      transfer_data: nil,
      trial_end: nil,
      trial_from_plan: nil,
      trial_period_days: nil,
      trial_settings: nil
    )
      @add_invoice_items = add_invoice_items
      @application_fee_percent = application_fee_percent
      @automatic_tax = automatic_tax
      @backdate_start_date = backdate_start_date
      @billing_cycle_anchor = billing_cycle_anchor
      @billing_cycle_anchor_config = billing_cycle_anchor_config
      @billing_mode = billing_mode
      @billing_thresholds = billing_thresholds
      @cancel_at = cancel_at
      @cancel_at_period_end = cancel_at_period_end
      @collection_method = collection_method
      @currency = currency
      @customer = customer
      @days_until_due = days_until_due
      @default_payment_method = default_payment_method
      @default_source = default_source
      @default_tax_rates = default_tax_rates
      @description = description
      @discounts = discounts
      @expand = expand
      @invoice_settings = invoice_settings
      @items = items
      @metadata = metadata
      @off_session = off_session
      @on_behalf_of = on_behalf_of
      @payment_behavior = payment_behavior
      @payment_settings = payment_settings
      @pending_invoice_item_interval = pending_invoice_item_interval
      @proration_behavior = proration_behavior
      @transfer_data = transfer_data
      @trial_end = trial_end
      @trial_from_plan = trial_from_plan
      @trial_period_days = trial_period_days
      @trial_settings = trial_settings
    end
  end
end
