# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  class InvoiceCreatePreviewParams < ::Stripe::RequestParams
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

    class CustomerDetails < ::Stripe::RequestParams
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

      class Shipping < ::Stripe::RequestParams
        class Address < ::Stripe::RequestParams
          # City, district, suburb, town, or village.
          attr_accessor :city
          # A freeform text field for the country. However, in order to activate some tax features, the format should be a two-letter country code ([ISO 3166-1 alpha-2](https://en.wikipedia.org/wiki/ISO_3166-1_alpha-2)).
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
        # Customer shipping address.
        attr_accessor :address
        # Customer name.
        attr_accessor :name
        # Customer phone (including extension).
        attr_accessor :phone

        def initialize(address: nil, name: nil, phone: nil)
          @address = address
          @name = name
          @phone = phone
        end
      end

      class Tax < ::Stripe::RequestParams
        # A recent IP address of the customer used for tax reporting and tax location inference. Stripe recommends updating the IP address when a new PaymentMethod is attached or the address field on the customer is updated. We recommend against updating this field more frequently since it could result in unexpected tax location/reporting outcomes.
        attr_accessor :ip_address

        def initialize(ip_address: nil)
          @ip_address = ip_address
        end
      end

      class TaxId < ::Stripe::RequestParams
        # Type of the tax ID, one of `ad_nrt`, `ae_trn`, `al_tin`, `am_tin`, `ao_tin`, `ar_cuit`, `au_abn`, `au_arn`, `aw_tin`, `az_tin`, `ba_tin`, `bb_tin`, `bd_bin`, `bf_ifu`, `bg_uic`, `bh_vat`, `bj_ifu`, `bo_tin`, `br_cnpj`, `br_cpf`, `bs_tin`, `by_tin`, `ca_bn`, `ca_gst_hst`, `ca_pst_bc`, `ca_pst_mb`, `ca_pst_sk`, `ca_qst`, `cd_nif`, `ch_uid`, `ch_vat`, `cl_tin`, `cm_niu`, `cn_tin`, `co_nit`, `cr_tin`, `cv_nif`, `de_stn`, `do_rcn`, `ec_ruc`, `eg_tin`, `es_cif`, `et_tin`, `eu_oss_vat`, `eu_vat`, `gb_vat`, `ge_vat`, `gn_nif`, `hk_br`, `hr_oib`, `hu_tin`, `id_npwp`, `il_vat`, `in_gst`, `is_vat`, `jp_cn`, `jp_rn`, `jp_trn`, `ke_pin`, `kg_tin`, `kh_tin`, `kr_brn`, `kz_bin`, `la_tin`, `li_uid`, `li_vat`, `ma_vat`, `md_vat`, `me_pib`, `mk_vat`, `mr_nif`, `mx_rfc`, `my_frp`, `my_itn`, `my_sst`, `ng_tin`, `no_vat`, `no_voec`, `np_pan`, `nz_gst`, `om_vat`, `pe_ruc`, `ph_tin`, `ro_tin`, `rs_pib`, `ru_inn`, `ru_kpp`, `sa_vat`, `sg_gst`, `sg_uen`, `si_tin`, `sn_ninea`, `sr_fin`, `sv_nit`, `th_vat`, `tj_tin`, `tr_tin`, `tw_vat`, `tz_vat`, `ua_vat`, `ug_tin`, `us_ein`, `uy_ruc`, `uz_tin`, `uz_vat`, `ve_rif`, `vn_tin`, `za_vat`, `zm_tin`, or `zw_tin`
        attr_accessor :type
        # Value of the tax ID.
        attr_accessor :value

        def initialize(type: nil, value: nil)
          @type = type
          @value = value
        end
      end
      # The customer's address.
      attr_accessor :address
      # The customer's shipping information. Appears on invoices emailed to this customer.
      attr_accessor :shipping
      # Tax details about the customer.
      attr_accessor :tax
      # The customer's tax exemption. One of `none`, `exempt`, or `reverse`.
      attr_accessor :tax_exempt
      # The customer's tax IDs.
      attr_accessor :tax_ids

      def initialize(address: nil, shipping: nil, tax: nil, tax_exempt: nil, tax_ids: nil)
        @address = address
        @shipping = shipping
        @tax = tax
        @tax_exempt = tax_exempt
        @tax_ids = tax_ids
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

    class InvoiceItem < ::Stripe::RequestParams
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
        # The end of the period, which must be greater than or equal to the start. This value is inclusive.
        attr_accessor :end
        # The start of the period. This value is inclusive.
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
        # A positive integer in cents (or local equivalent) (or 0 for a free price) representing how much to charge.
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
      # The integer amount in cents (or local equivalent) of previewed invoice item.
      attr_accessor :amount
      # Three-letter [ISO currency code](https://www.iso.org/iso-4217-currency-codes.html), in lowercase. Must be a [supported currency](https://stripe.com/docs/currencies). Only applicable to new invoice items.
      attr_accessor :currency
      # An arbitrary string which you can attach to the invoice item. The description is displayed in the invoice for easy tracking.
      attr_accessor :description
      # Explicitly controls whether discounts apply to this invoice item. Defaults to true, except for negative invoice items.
      attr_accessor :discountable
      # The coupons to redeem into discounts for the invoice item in the preview.
      attr_accessor :discounts
      # The ID of the invoice item to update in preview. If not specified, a new invoice item will be added to the preview of the upcoming invoice.
      attr_accessor :invoiceitem
      # Set of [key-value pairs](https://stripe.com/docs/api/metadata) that you can attach to an object. This can be useful for storing additional information about the object in a structured format. Individual keys can be unset by posting an empty value to them. All keys can be unset by posting an empty value to `metadata`.
      attr_accessor :metadata
      # The period associated with this invoice item. When set to different values, the period will be rendered on the invoice. If you have [Stripe Revenue Recognition](https://stripe.com/docs/revenue-recognition) enabled, the period will be used to recognize and defer revenue. See the [Revenue Recognition documentation](https://stripe.com/docs/revenue-recognition/methodology/subscriptions-and-invoicing) for details.
      attr_accessor :period
      # The ID of the price object. One of `price` or `price_data` is required.
      attr_accessor :price
      # Data used to generate a new [Price](https://stripe.com/docs/api/prices) object inline. One of `price` or `price_data` is required.
      attr_accessor :price_data
      # Non-negative integer. The quantity of units for the invoice item.
      attr_accessor :quantity
      # Only required if a [default tax behavior](https://stripe.com/docs/tax/products-prices-tax-categories-tax-behavior#setting-a-default-tax-behavior-(recommended)) was not provided in the Stripe Tax settings. Specifies whether the price is considered inclusive of taxes or exclusive of taxes. One of `inclusive`, `exclusive`, or `unspecified`. Once specified as either `inclusive` or `exclusive`, it cannot be changed.
      attr_accessor :tax_behavior
      # A [tax code](https://stripe.com/docs/tax/tax-categories) ID.
      attr_accessor :tax_code
      # The tax rates that apply to the item. When set, any `default_tax_rates` do not apply to this item.
      attr_accessor :tax_rates
      # The integer unit amount in cents (or local equivalent) of the charge to be applied to the upcoming invoice. This unit_amount will be multiplied by the quantity to get the full amount. If you want to apply a credit to the customer's account, pass a negative unit_amount.
      attr_accessor :unit_amount
      # Same as `unit_amount`, but accepts a decimal value in cents (or local equivalent) with at most 12 decimal places. Only one of `unit_amount` and `unit_amount_decimal` can be set.
      attr_accessor :unit_amount_decimal

      def initialize(
        amount: nil,
        currency: nil,
        description: nil,
        discountable: nil,
        discounts: nil,
        invoiceitem: nil,
        metadata: nil,
        period: nil,
        price: nil,
        price_data: nil,
        quantity: nil,
        tax_behavior: nil,
        tax_code: nil,
        tax_rates: nil,
        unit_amount: nil,
        unit_amount_decimal: nil
      )
        @amount = amount
        @currency = currency
        @description = description
        @discountable = discountable
        @discounts = discounts
        @invoiceitem = invoiceitem
        @metadata = metadata
        @period = period
        @price = price
        @price_data = price_data
        @quantity = quantity
        @tax_behavior = tax_behavior
        @tax_code = tax_code
        @tax_rates = tax_rates
        @unit_amount = unit_amount
        @unit_amount_decimal = unit_amount_decimal
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

    class ScheduleDetails < ::Stripe::RequestParams
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

      class Phase < ::Stripe::RequestParams
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

        class Duration < ::Stripe::RequestParams
          # Specifies phase duration. Either `day`, `week`, `month` or `year`.
          attr_accessor :interval
          # The multiplier applied to the interval.
          attr_accessor :interval_count

          def initialize(interval: nil, interval_count: nil)
            @interval = interval
            @interval_count = interval_count
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
          # The account tax IDs associated with this phase of the subscription schedule. Will be set on invoices generated by this phase of the subscription schedule.
          attr_accessor :account_tax_ids
          # Number of days within which a customer must pay invoices generated by this subscription schedule. This value will be `null` for subscription schedules where `billing=charge_automatically`.
          attr_accessor :days_until_due
          # The connected account that issues the invoice. The invoice is presented with the branding and support information of the specified account.
          attr_accessor :issuer

          def initialize(account_tax_ids: nil, days_until_due: nil, issuer: nil)
            @account_tax_ids = account_tax_ids
            @days_until_due = days_until_due
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
          # Set of [key-value pairs](https://stripe.com/docs/api/metadata) that you can attach to a configuration item. Metadata on a configuration item will update the underlying subscription item's `metadata` when the phase is entered, adding new keys and replacing existing keys. Individual keys in the subscription item's `metadata` can be unset by posting an empty value to them in the configuration item's `metadata`. To unset all keys in the subscription item's `metadata`, update the subscription item directly or unset every key individually from the configuration item's `metadata`.
          attr_accessor :metadata
          # The plan ID to subscribe to. You may specify the same ID in `plan` and `price`.
          attr_accessor :plan
          # The ID of the price object.
          attr_accessor :price
          # Data used to generate a new [Price](https://stripe.com/docs/api/prices) object inline.
          attr_accessor :price_data
          # Quantity for the given price. Can be set only if the price's `usage_type` is `licensed` and not `metered`.
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
        # A list of prices and quantities that will generate invoice items appended to the next invoice for this phase. You may pass up to 20 items.
        attr_accessor :add_invoice_items
        # A non-negative decimal between 0 and 100, with at most two decimal places. This represents the percentage of the subscription invoice total that will be transferred to the application owner's Stripe account. The request must be made by a platform account on a connected account in order to set an application fee percentage. For more information, see the application fees [documentation](https://stripe.com/docs/connect/subscriptions#collecting-fees-on-subscriptions).
        attr_accessor :application_fee_percent
        # Automatic tax settings for this phase.
        attr_accessor :automatic_tax
        # Can be set to `phase_start` to set the anchor to the start of the phase or `automatic` to automatically change it if needed. Cannot be set to `phase_start` if this phase specifies a trial. For more information, see the billing cycle [documentation](https://stripe.com/docs/billing/subscriptions/billing-cycle).
        attr_accessor :billing_cycle_anchor
        # Define thresholds at which an invoice will be sent, and the subscription advanced to a new billing period. Pass an empty string to remove previously-defined thresholds.
        attr_accessor :billing_thresholds
        # Either `charge_automatically`, or `send_invoice`. When charging automatically, Stripe will attempt to pay the underlying subscription at the end of each billing cycle using the default source attached to the customer. When sending an invoice, Stripe will email your customer an invoice with payment instructions and mark the subscription as `active`. Defaults to `charge_automatically` on creation.
        attr_accessor :collection_method
        # Three-letter [ISO currency code](https://www.iso.org/iso-4217-currency-codes.html), in lowercase. Must be a [supported currency](https://stripe.com/docs/currencies).
        attr_accessor :currency
        # ID of the default payment method for the subscription schedule. It must belong to the customer associated with the subscription schedule. If not set, invoices will use the default payment method in the customer's invoice settings.
        attr_accessor :default_payment_method
        # A list of [Tax Rate](https://stripe.com/docs/api/tax_rates) ids. These Tax Rates will set the Subscription's [`default_tax_rates`](https://stripe.com/docs/api/subscriptions/create#create_subscription-default_tax_rates), which means they will be the Invoice's [`default_tax_rates`](https://stripe.com/docs/api/invoices/create#create_invoice-default_tax_rates) for any Invoices issued by the Subscription during this Phase.
        attr_accessor :default_tax_rates
        # Subscription description, meant to be displayable to the customer. Use this field to optionally store an explanation of the subscription for rendering in Stripe surfaces and certain local payment methods UIs.
        attr_accessor :description
        # The coupons to redeem into discounts for the schedule phase. If not specified, inherits the discount from the subscription's customer. Pass an empty string to avoid inheriting any discounts.
        attr_accessor :discounts
        # The number of intervals the phase should last. If set, `end_date` must not be set.
        attr_accessor :duration
        # The date at which this phase of the subscription schedule ends. If set, `iterations` must not be set.
        attr_accessor :end_date
        # All invoices will be billed using the specified settings.
        attr_accessor :invoice_settings
        # List of configuration items, each with an attached price, to apply during this phase of the subscription schedule.
        attr_accessor :items
        # Set of [key-value pairs](https://stripe.com/docs/api/metadata) that you can attach to a phase. Metadata on a schedule's phase will update the underlying subscription's `metadata` when the phase is entered, adding new keys and replacing existing keys in the subscription's `metadata`. Individual keys in the subscription's `metadata` can be unset by posting an empty value to them in the phase's `metadata`. To unset all keys in the subscription's `metadata`, update the subscription directly or unset every key individually from the phase's `metadata`.
        attr_accessor :metadata
        # The account on behalf of which to charge, for each of the associated subscription's invoices.
        attr_accessor :on_behalf_of
        # Controls whether the subscription schedule should create [prorations](https://stripe.com/docs/billing/subscriptions/prorations) when transitioning to this phase if there is a difference in billing configuration. It's different from the request-level [proration_behavior](https://stripe.com/docs/api/subscription_schedules/update#update_subscription_schedule-proration_behavior) parameter which controls what happens if the update request affects the billing configuration (item price, quantity, etc.) of the current phase.
        attr_accessor :proration_behavior
        # The date at which this phase of the subscription schedule starts or `now`. Must be set on the first phase.
        attr_accessor :start_date
        # The data with which to automatically create a Transfer for each of the associated subscription's invoices.
        attr_accessor :transfer_data
        # If set to true the entire phase is counted as a trial and the customer will not be charged for any fees.
        attr_accessor :trial
        # Sets the phase to trialing from the start date to this date. Must be before the phase end date, can not be combined with `trial`
        attr_accessor :trial_end

        def initialize(
          add_invoice_items: nil,
          application_fee_percent: nil,
          automatic_tax: nil,
          billing_cycle_anchor: nil,
          billing_thresholds: nil,
          collection_method: nil,
          currency: nil,
          default_payment_method: nil,
          default_tax_rates: nil,
          description: nil,
          discounts: nil,
          duration: nil,
          end_date: nil,
          invoice_settings: nil,
          items: nil,
          metadata: nil,
          on_behalf_of: nil,
          proration_behavior: nil,
          start_date: nil,
          transfer_data: nil,
          trial: nil,
          trial_end: nil
        )
          @add_invoice_items = add_invoice_items
          @application_fee_percent = application_fee_percent
          @automatic_tax = automatic_tax
          @billing_cycle_anchor = billing_cycle_anchor
          @billing_thresholds = billing_thresholds
          @collection_method = collection_method
          @currency = currency
          @default_payment_method = default_payment_method
          @default_tax_rates = default_tax_rates
          @description = description
          @discounts = discounts
          @duration = duration
          @end_date = end_date
          @invoice_settings = invoice_settings
          @items = items
          @metadata = metadata
          @on_behalf_of = on_behalf_of
          @proration_behavior = proration_behavior
          @start_date = start_date
          @transfer_data = transfer_data
          @trial = trial
          @trial_end = trial_end
        end
      end
      # Controls how prorations and invoices for subscriptions are calculated and orchestrated.
      attr_accessor :billing_mode
      # Behavior of the subscription schedule and underlying subscription when it ends. Possible values are `release` or `cancel` with the default being `release`. `release` will end the subscription schedule and keep the underlying subscription running. `cancel` will end the subscription schedule and cancel the underlying subscription.
      attr_accessor :end_behavior
      # List representing phases of the subscription schedule. Each phase can be customized to have different durations, plans, and coupons. If there are multiple phases, the `end_date` of one phase will always equal the `start_date` of the next phase.
      attr_accessor :phases
      # In cases where the `schedule_details` params update the currently active phase, specifies if and how to prorate at the time of the request.
      attr_accessor :proration_behavior

      def initialize(billing_mode: nil, end_behavior: nil, phases: nil, proration_behavior: nil)
        @billing_mode = billing_mode
        @end_behavior = end_behavior
        @phases = phases
        @proration_behavior = proration_behavior
      end
    end

    class SubscriptionDetails < ::Stripe::RequestParams
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
        # Delete all usage for a given subscription item. You must pass this when deleting a usage records subscription item. `clear_usage` has no effect if the plan has a billing meter attached.
        attr_accessor :clear_usage
        # A flag that, if set to `true`, will delete the specified item.
        attr_accessor :deleted
        # The coupons to redeem into discounts for the subscription item.
        attr_accessor :discounts
        # Subscription item to update.
        attr_accessor :id
        # Set of [key-value pairs](https://stripe.com/docs/api/metadata) that you can attach to an object. This can be useful for storing additional information about the object in a structured format. Individual keys can be unset by posting an empty value to them. All keys can be unset by posting an empty value to `metadata`.
        attr_accessor :metadata
        # Plan ID for this item, as a string.
        attr_accessor :plan
        # The ID of the price object. One of `price` or `price_data` is required. When changing a subscription item's price, `quantity` is set to 1 unless a `quantity` parameter is provided.
        attr_accessor :price
        # Data used to generate a new [Price](https://stripe.com/docs/api/prices) object inline. One of `price` or `price_data` is required.
        attr_accessor :price_data
        # Quantity for this item.
        attr_accessor :quantity
        # A list of [Tax Rate](https://stripe.com/docs/api/tax_rates) ids. These Tax Rates will override the [`default_tax_rates`](https://stripe.com/docs/api/subscriptions/create#create_subscription-default_tax_rates) on the Subscription. When updating, pass an empty string to remove previously-defined tax rates.
        attr_accessor :tax_rates

        def initialize(
          billing_thresholds: nil,
          clear_usage: nil,
          deleted: nil,
          discounts: nil,
          id: nil,
          metadata: nil,
          plan: nil,
          price: nil,
          price_data: nil,
          quantity: nil,
          tax_rates: nil
        )
          @billing_thresholds = billing_thresholds
          @clear_usage = clear_usage
          @deleted = deleted
          @discounts = discounts
          @id = id
          @metadata = metadata
          @plan = plan
          @price = price
          @price_data = price_data
          @quantity = quantity
          @tax_rates = tax_rates
        end
      end
      # For new subscriptions, a future timestamp to anchor the subscription's [billing cycle](https://stripe.com/docs/subscriptions/billing-cycle). This is used to determine the date of the first full invoice, and, for plans with `month` or `year` intervals, the day of the month for subsequent invoices. For existing subscriptions, the value can only be set to `now` or `unchanged`.
      attr_accessor :billing_cycle_anchor
      # Controls how prorations and invoices for subscriptions are calculated and orchestrated.
      attr_accessor :billing_mode
      # A timestamp at which the subscription should cancel. If set to a date before the current period ends, this will cause a proration if prorations have been enabled using `proration_behavior`. If set during a future period, this will always cause a proration for that period.
      attr_accessor :cancel_at
      # Indicate whether this subscription should cancel at the end of the current period (`current_period_end`). Defaults to `false`.
      attr_accessor :cancel_at_period_end
      # This simulates the subscription being canceled or expired immediately.
      attr_accessor :cancel_now
      # If provided, the invoice returned will preview updating or creating a subscription with these default tax rates. The default tax rates will apply to any line item that does not have `tax_rates` set.
      attr_accessor :default_tax_rates
      # A list of up to 20 subscription items, each with an attached price.
      attr_accessor :items
      # Determines how to handle [prorations](https://stripe.com/docs/billing/subscriptions/prorations) when the billing cycle changes (e.g., when switching plans, resetting `billing_cycle_anchor=now`, or starting a trial), or if an item's `quantity` changes. The default value is `create_prorations`.
      attr_accessor :proration_behavior
      # If previewing an update to a subscription, and doing proration, `subscription_details.proration_date` forces the proration to be calculated as though the update was done at the specified time. The time given must be within the current subscription period and within the current phase of the schedule backing this subscription, if the schedule exists. If set, `subscription`, and one of `subscription_details.items`, or `subscription_details.trial_end` are required. Also, `subscription_details.proration_behavior` cannot be set to 'none'.
      attr_accessor :proration_date
      # For paused subscriptions, setting `subscription_details.resume_at` to `now` will preview the invoice that will be generated if the subscription is resumed.
      attr_accessor :resume_at
      # Date a subscription is intended to start (can be future or past).
      attr_accessor :start_date
      # If provided, the invoice returned will preview updating or creating a subscription with that trial end. If set, one of `subscription_details.items` or `subscription` is required.
      attr_accessor :trial_end

      def initialize(
        billing_cycle_anchor: nil,
        billing_mode: nil,
        cancel_at: nil,
        cancel_at_period_end: nil,
        cancel_now: nil,
        default_tax_rates: nil,
        items: nil,
        proration_behavior: nil,
        proration_date: nil,
        resume_at: nil,
        start_date: nil,
        trial_end: nil
      )
        @billing_cycle_anchor = billing_cycle_anchor
        @billing_mode = billing_mode
        @cancel_at = cancel_at
        @cancel_at_period_end = cancel_at_period_end
        @cancel_now = cancel_now
        @default_tax_rates = default_tax_rates
        @items = items
        @proration_behavior = proration_behavior
        @proration_date = proration_date
        @resume_at = resume_at
        @start_date = start_date
        @trial_end = trial_end
      end
    end
    # Settings for automatic tax lookup for this invoice preview.
    attr_accessor :automatic_tax
    # The currency to preview this invoice in. Defaults to that of `customer` if not specified.
    attr_accessor :currency
    # The identifier of the customer whose upcoming invoice you'd like to retrieve. If `automatic_tax` is enabled then one of `customer`, `customer_details`, `subscription`, or `schedule` must be set.
    attr_accessor :customer
    # Details about the customer you want to invoice or overrides for an existing customer. If `automatic_tax` is enabled then one of `customer`, `customer_details`, `subscription`, or `schedule` must be set.
    attr_accessor :customer_details
    # The coupons to redeem into discounts for the invoice preview. If not specified, inherits the discount from the subscription or customer. This works for both coupons directly applied to an invoice and coupons applied to a subscription. Pass an empty string to avoid inheriting any discounts.
    attr_accessor :discounts
    # Specifies which fields in the response should be expanded.
    attr_accessor :expand
    # List of invoice items to add or update in the upcoming invoice preview (up to 250).
    attr_accessor :invoice_items
    # The connected account that issues the invoice. The invoice is presented with the branding and support information of the specified account.
    attr_accessor :issuer
    # The account (if any) for which the funds of the invoice payment are intended. If set, the invoice will be presented with the branding and support information of the specified account. See the [Invoices with Connect](https://stripe.com/docs/billing/invoices/connect) documentation for details.
    attr_accessor :on_behalf_of
    # Customizes the types of values to include when calculating the invoice. Defaults to `next` if unspecified.
    attr_accessor :preview_mode
    # The identifier of the schedule whose upcoming invoice you'd like to retrieve. Cannot be used with subscription or subscription fields.
    attr_accessor :schedule
    # The schedule creation or modification params to apply as a preview. Cannot be used with `subscription` or `subscription_` prefixed fields.
    attr_accessor :schedule_details
    # The identifier of the subscription for which you'd like to retrieve the upcoming invoice. If not provided, but a `subscription_details.items` is provided, you will preview creating a subscription with those items. If neither `subscription` nor `subscription_details.items` is provided, you will retrieve the next upcoming invoice from among the customer's subscriptions.
    attr_accessor :subscription
    # The subscription creation or modification params to apply as a preview. Cannot be used with `schedule` or `schedule_details` fields.
    attr_accessor :subscription_details

    def initialize(
      automatic_tax: nil,
      currency: nil,
      customer: nil,
      customer_details: nil,
      discounts: nil,
      expand: nil,
      invoice_items: nil,
      issuer: nil,
      on_behalf_of: nil,
      preview_mode: nil,
      schedule: nil,
      schedule_details: nil,
      subscription: nil,
      subscription_details: nil
    )
      @automatic_tax = automatic_tax
      @currency = currency
      @customer = customer
      @customer_details = customer_details
      @discounts = discounts
      @expand = expand
      @invoice_items = invoice_items
      @issuer = issuer
      @on_behalf_of = on_behalf_of
      @preview_mode = preview_mode
      @schedule = schedule
      @schedule_details = schedule_details
      @subscription = subscription
      @subscription_details = subscription_details
    end
  end
end
