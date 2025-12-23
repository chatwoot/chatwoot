# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  class PriceCreateParams < ::Stripe::RequestParams
    class CurrencyOptions < ::Stripe::RequestParams
      class CustomUnitAmount < ::Stripe::RequestParams
        # Pass in `true` to enable `custom_unit_amount`, otherwise omit `custom_unit_amount`.
        attr_accessor :enabled
        # The maximum unit amount the customer can specify for this item.
        attr_accessor :maximum
        # The minimum unit amount the customer can specify for this item. Must be at least the minimum charge amount.
        attr_accessor :minimum
        # The starting unit amount which can be updated by the customer.
        attr_accessor :preset

        def initialize(enabled: nil, maximum: nil, minimum: nil, preset: nil)
          @enabled = enabled
          @maximum = maximum
          @minimum = minimum
          @preset = preset
        end
      end

      class Tier < ::Stripe::RequestParams
        # The flat billing amount for an entire tier, regardless of the number of units in the tier.
        attr_accessor :flat_amount
        # Same as `flat_amount`, but accepts a decimal value representing an integer in the minor units of the currency. Only one of `flat_amount` and `flat_amount_decimal` can be set.
        attr_accessor :flat_amount_decimal
        # The per unit billing amount for each individual unit for which this tier applies.
        attr_accessor :unit_amount
        # Same as `unit_amount`, but accepts a decimal value in cents (or local equivalent) with at most 12 decimal places. Only one of `unit_amount` and `unit_amount_decimal` can be set.
        attr_accessor :unit_amount_decimal
        # Specifies the upper bound of this tier. The lower bound of a tier is the upper bound of the previous tier adding one. Use `inf` to define a fallback tier.
        attr_accessor :up_to

        def initialize(
          flat_amount: nil,
          flat_amount_decimal: nil,
          unit_amount: nil,
          unit_amount_decimal: nil,
          up_to: nil
        )
          @flat_amount = flat_amount
          @flat_amount_decimal = flat_amount_decimal
          @unit_amount = unit_amount
          @unit_amount_decimal = unit_amount_decimal
          @up_to = up_to
        end
      end
      # When set, provides configuration for the amount to be adjusted by the customer during Checkout Sessions and Payment Links.
      attr_accessor :custom_unit_amount
      # Only required if a [default tax behavior](https://stripe.com/docs/tax/products-prices-tax-categories-tax-behavior#setting-a-default-tax-behavior-(recommended)) was not provided in the Stripe Tax settings. Specifies whether the price is considered inclusive of taxes or exclusive of taxes. One of `inclusive`, `exclusive`, or `unspecified`. Once specified as either `inclusive` or `exclusive`, it cannot be changed.
      attr_accessor :tax_behavior
      # Each element represents a pricing tier. This parameter requires `billing_scheme` to be set to `tiered`. See also the documentation for `billing_scheme`.
      attr_accessor :tiers
      # A positive integer in cents (or local equivalent) (or 0 for a free price) representing how much to charge.
      attr_accessor :unit_amount
      # Same as `unit_amount`, but accepts a decimal value in cents (or local equivalent) with at most 12 decimal places. Only one of `unit_amount` and `unit_amount_decimal` can be set.
      attr_accessor :unit_amount_decimal

      def initialize(
        custom_unit_amount: nil,
        tax_behavior: nil,
        tiers: nil,
        unit_amount: nil,
        unit_amount_decimal: nil
      )
        @custom_unit_amount = custom_unit_amount
        @tax_behavior = tax_behavior
        @tiers = tiers
        @unit_amount = unit_amount
        @unit_amount_decimal = unit_amount_decimal
      end
    end

    class CustomUnitAmount < ::Stripe::RequestParams
      # Pass in `true` to enable `custom_unit_amount`, otherwise omit `custom_unit_amount`.
      attr_accessor :enabled
      # The maximum unit amount the customer can specify for this item.
      attr_accessor :maximum
      # The minimum unit amount the customer can specify for this item. Must be at least the minimum charge amount.
      attr_accessor :minimum
      # The starting unit amount which can be updated by the customer.
      attr_accessor :preset

      def initialize(enabled: nil, maximum: nil, minimum: nil, preset: nil)
        @enabled = enabled
        @maximum = maximum
        @minimum = minimum
        @preset = preset
      end
    end

    class ProductData < ::Stripe::RequestParams
      # Whether the product is currently available for purchase. Defaults to `true`.
      attr_accessor :active
      # The identifier for the product. Must be unique. If not provided, an identifier will be randomly generated.
      attr_accessor :id
      # Set of [key-value pairs](https://stripe.com/docs/api/metadata) that you can attach to an object. This can be useful for storing additional information about the object in a structured format. Individual keys can be unset by posting an empty value to them. All keys can be unset by posting an empty value to `metadata`.
      attr_accessor :metadata
      # The product's name, meant to be displayable to the customer.
      attr_accessor :name
      # An arbitrary string to be displayed on your customer's credit card or bank statement. While most banks display this information consistently, some may display it incorrectly or not at all.
      #
      # This may be up to 22 characters. The statement description may not include `<`, `>`, `\`, `"`, `'` characters, and will appear on your customer's statement in capital letters. Non-ASCII characters are automatically stripped.
      attr_accessor :statement_descriptor
      # A [tax code](https://stripe.com/docs/tax/tax-categories) ID.
      attr_accessor :tax_code
      # A label that represents units of this product. When set, this will be included in customers' receipts, invoices, Checkout, and the customer portal.
      attr_accessor :unit_label

      def initialize(
        active: nil,
        id: nil,
        metadata: nil,
        name: nil,
        statement_descriptor: nil,
        tax_code: nil,
        unit_label: nil
      )
        @active = active
        @id = id
        @metadata = metadata
        @name = name
        @statement_descriptor = statement_descriptor
        @tax_code = tax_code
        @unit_label = unit_label
      end
    end

    class Recurring < ::Stripe::RequestParams
      # Specifies billing frequency. Either `day`, `week`, `month` or `year`.
      attr_accessor :interval
      # The number of intervals between subscription billings. For example, `interval=month` and `interval_count=3` bills every 3 months. Maximum of three years interval allowed (3 years, 36 months, or 156 weeks).
      attr_accessor :interval_count
      # The meter tracking the usage of a metered price
      attr_accessor :meter
      # Default number of trial days when subscribing a customer to this price using [`trial_from_plan=true`](https://stripe.com/docs/api#create_subscription-trial_from_plan).
      attr_accessor :trial_period_days
      # Configures how the quantity per period should be determined. Can be either `metered` or `licensed`. `licensed` automatically bills the `quantity` set when adding it to a subscription. `metered` aggregates the total usage based on usage records. Defaults to `licensed`.
      attr_accessor :usage_type

      def initialize(
        interval: nil,
        interval_count: nil,
        meter: nil,
        trial_period_days: nil,
        usage_type: nil
      )
        @interval = interval
        @interval_count = interval_count
        @meter = meter
        @trial_period_days = trial_period_days
        @usage_type = usage_type
      end
    end

    class Tier < ::Stripe::RequestParams
      # The flat billing amount for an entire tier, regardless of the number of units in the tier.
      attr_accessor :flat_amount
      # Same as `flat_amount`, but accepts a decimal value representing an integer in the minor units of the currency. Only one of `flat_amount` and `flat_amount_decimal` can be set.
      attr_accessor :flat_amount_decimal
      # The per unit billing amount for each individual unit for which this tier applies.
      attr_accessor :unit_amount
      # Same as `unit_amount`, but accepts a decimal value in cents (or local equivalent) with at most 12 decimal places. Only one of `unit_amount` and `unit_amount_decimal` can be set.
      attr_accessor :unit_amount_decimal
      # Specifies the upper bound of this tier. The lower bound of a tier is the upper bound of the previous tier adding one. Use `inf` to define a fallback tier.
      attr_accessor :up_to

      def initialize(
        flat_amount: nil,
        flat_amount_decimal: nil,
        unit_amount: nil,
        unit_amount_decimal: nil,
        up_to: nil
      )
        @flat_amount = flat_amount
        @flat_amount_decimal = flat_amount_decimal
        @unit_amount = unit_amount
        @unit_amount_decimal = unit_amount_decimal
        @up_to = up_to
      end
    end

    class TransformQuantity < ::Stripe::RequestParams
      # Divide usage by this number.
      attr_accessor :divide_by
      # After division, either round the result `up` or `down`.
      attr_accessor :round

      def initialize(divide_by: nil, round: nil)
        @divide_by = divide_by
        @round = round
      end
    end
    # Whether the price can be used for new purchases. Defaults to `true`.
    attr_accessor :active
    # Describes how to compute the price per period. Either `per_unit` or `tiered`. `per_unit` indicates that the fixed amount (specified in `unit_amount` or `unit_amount_decimal`) will be charged per unit in `quantity` (for prices with `usage_type=licensed`), or per unit of total usage (for prices with `usage_type=metered`). `tiered` indicates that the unit pricing will be computed using a tiering strategy as defined using the `tiers` and `tiers_mode` attributes.
    attr_accessor :billing_scheme
    # Three-letter [ISO currency code](https://www.iso.org/iso-4217-currency-codes.html), in lowercase. Must be a [supported currency](https://stripe.com/docs/currencies).
    attr_accessor :currency
    # Prices defined in each available currency option. Each key must be a three-letter [ISO currency code](https://www.iso.org/iso-4217-currency-codes.html) and a [supported currency](https://stripe.com/docs/currencies).
    attr_accessor :currency_options
    # When set, provides configuration for the amount to be adjusted by the customer during Checkout Sessions and Payment Links.
    attr_accessor :custom_unit_amount
    # Specifies which fields in the response should be expanded.
    attr_accessor :expand
    # A lookup key used to retrieve prices dynamically from a static string. This may be up to 200 characters.
    attr_accessor :lookup_key
    # Set of [key-value pairs](https://stripe.com/docs/api/metadata) that you can attach to an object. This can be useful for storing additional information about the object in a structured format. Individual keys can be unset by posting an empty value to them. All keys can be unset by posting an empty value to `metadata`.
    attr_accessor :metadata
    # A brief description of the price, hidden from customers.
    attr_accessor :nickname
    # The ID of the [Product](https://docs.stripe.com/api/products) that this [Price](https://docs.stripe.com/api/prices) will belong to.
    attr_accessor :product
    # These fields can be used to create a new product that this price will belong to.
    attr_accessor :product_data
    # The recurring components of a price such as `interval` and `usage_type`.
    attr_accessor :recurring
    # Only required if a [default tax behavior](https://stripe.com/docs/tax/products-prices-tax-categories-tax-behavior#setting-a-default-tax-behavior-(recommended)) was not provided in the Stripe Tax settings. Specifies whether the price is considered inclusive of taxes or exclusive of taxes. One of `inclusive`, `exclusive`, or `unspecified`. Once specified as either `inclusive` or `exclusive`, it cannot be changed.
    attr_accessor :tax_behavior
    # Each element represents a pricing tier. This parameter requires `billing_scheme` to be set to `tiered`. See also the documentation for `billing_scheme`.
    attr_accessor :tiers
    # Defines if the tiering price should be `graduated` or `volume` based. In `volume`-based tiering, the maximum quantity within a period determines the per unit price, in `graduated` tiering pricing can successively change as the quantity grows.
    attr_accessor :tiers_mode
    # If set to true, will atomically remove the lookup key from the existing price, and assign it to this price.
    attr_accessor :transfer_lookup_key
    # Apply a transformation to the reported usage or set quantity before computing the billed price. Cannot be combined with `tiers`.
    attr_accessor :transform_quantity
    # A positive integer in cents (or local equivalent) (or 0 for a free price) representing how much to charge. One of `unit_amount`, `unit_amount_decimal`, or `custom_unit_amount` is required, unless `billing_scheme=tiered`.
    attr_accessor :unit_amount
    # Same as `unit_amount`, but accepts a decimal value in cents (or local equivalent) with at most 12 decimal places. Only one of `unit_amount` and `unit_amount_decimal` can be set.
    attr_accessor :unit_amount_decimal

    def initialize(
      active: nil,
      billing_scheme: nil,
      currency: nil,
      currency_options: nil,
      custom_unit_amount: nil,
      expand: nil,
      lookup_key: nil,
      metadata: nil,
      nickname: nil,
      product: nil,
      product_data: nil,
      recurring: nil,
      tax_behavior: nil,
      tiers: nil,
      tiers_mode: nil,
      transfer_lookup_key: nil,
      transform_quantity: nil,
      unit_amount: nil,
      unit_amount_decimal: nil
    )
      @active = active
      @billing_scheme = billing_scheme
      @currency = currency
      @currency_options = currency_options
      @custom_unit_amount = custom_unit_amount
      @expand = expand
      @lookup_key = lookup_key
      @metadata = metadata
      @nickname = nickname
      @product = product
      @product_data = product_data
      @recurring = recurring
      @tax_behavior = tax_behavior
      @tiers = tiers
      @tiers_mode = tiers_mode
      @transfer_lookup_key = transfer_lookup_key
      @transform_quantity = transform_quantity
      @unit_amount = unit_amount
      @unit_amount_decimal = unit_amount_decimal
    end
  end
end
