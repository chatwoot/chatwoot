# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  class ProductCreateParams < ::Stripe::RequestParams
    class DefaultPriceData < ::Stripe::RequestParams
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
      # Prices defined in each available currency option. Each key must be a three-letter [ISO currency code](https://www.iso.org/iso-4217-currency-codes.html) and a [supported currency](https://stripe.com/docs/currencies).
      attr_accessor :currency_options
      # When set, provides configuration for the amount to be adjusted by the customer during Checkout Sessions and Payment Links.
      attr_accessor :custom_unit_amount
      # Set of [key-value pairs](https://stripe.com/docs/api/metadata) that you can attach to an object. This can be useful for storing additional information about the object in a structured format. Individual keys can be unset by posting an empty value to them. All keys can be unset by posting an empty value to `metadata`.
      attr_accessor :metadata
      # The recurring components of a price such as `interval` and `interval_count`.
      attr_accessor :recurring
      # Only required if a [default tax behavior](https://stripe.com/docs/tax/products-prices-tax-categories-tax-behavior#setting-a-default-tax-behavior-(recommended)) was not provided in the Stripe Tax settings. Specifies whether the price is considered inclusive of taxes or exclusive of taxes. One of `inclusive`, `exclusive`, or `unspecified`. Once specified as either `inclusive` or `exclusive`, it cannot be changed.
      attr_accessor :tax_behavior
      # A positive integer in cents (or local equivalent) (or 0 for a free price) representing how much to charge. One of `unit_amount`, `unit_amount_decimal`, or `custom_unit_amount` is required.
      attr_accessor :unit_amount
      # Same as `unit_amount`, but accepts a decimal value in cents (or local equivalent) with at most 12 decimal places. Only one of `unit_amount` and `unit_amount_decimal` can be set.
      attr_accessor :unit_amount_decimal

      def initialize(
        currency: nil,
        currency_options: nil,
        custom_unit_amount: nil,
        metadata: nil,
        recurring: nil,
        tax_behavior: nil,
        unit_amount: nil,
        unit_amount_decimal: nil
      )
        @currency = currency
        @currency_options = currency_options
        @custom_unit_amount = custom_unit_amount
        @metadata = metadata
        @recurring = recurring
        @tax_behavior = tax_behavior
        @unit_amount = unit_amount
        @unit_amount_decimal = unit_amount_decimal
      end
    end

    class MarketingFeature < ::Stripe::RequestParams
      # The marketing feature name. Up to 80 characters long.
      attr_accessor :name

      def initialize(name: nil)
        @name = name
      end
    end

    class PackageDimensions < ::Stripe::RequestParams
      # Height, in inches. Maximum precision is 2 decimal places.
      attr_accessor :height
      # Length, in inches. Maximum precision is 2 decimal places.
      attr_accessor :length
      # Weight, in ounces. Maximum precision is 2 decimal places.
      attr_accessor :weight
      # Width, in inches. Maximum precision is 2 decimal places.
      attr_accessor :width

      def initialize(height: nil, length: nil, weight: nil, width: nil)
        @height = height
        @length = length
        @weight = weight
        @width = width
      end
    end
    # Whether the product is currently available for purchase. Defaults to `true`.
    attr_accessor :active
    # Data used to generate a new [Price](https://stripe.com/docs/api/prices) object. This Price will be set as the default price for this product.
    attr_accessor :default_price_data
    # The product's description, meant to be displayable to the customer. Use this field to optionally store a long form explanation of the product being sold for your own rendering purposes.
    attr_accessor :description
    # Specifies which fields in the response should be expanded.
    attr_accessor :expand
    # An identifier will be randomly generated by Stripe. You can optionally override this ID, but the ID must be unique across all products in your Stripe account.
    attr_accessor :id
    # A list of up to 8 URLs of images for this product, meant to be displayable to the customer.
    attr_accessor :images
    # A list of up to 15 marketing features for this product. These are displayed in [pricing tables](https://stripe.com/docs/payments/checkout/pricing-table).
    attr_accessor :marketing_features
    # Set of [key-value pairs](https://stripe.com/docs/api/metadata) that you can attach to an object. This can be useful for storing additional information about the object in a structured format. Individual keys can be unset by posting an empty value to them. All keys can be unset by posting an empty value to `metadata`.
    attr_accessor :metadata
    # The product's name, meant to be displayable to the customer.
    attr_accessor :name
    # The dimensions of this product for shipping purposes.
    attr_accessor :package_dimensions
    # Whether this product is shipped (i.e., physical goods).
    attr_accessor :shippable
    # An arbitrary string to be displayed on your customer's credit card or bank statement. While most banks display this information consistently, some may display it incorrectly or not at all.
    #
    # This may be up to 22 characters. The statement description may not include `<`, `>`, `\`, `"`, `'` characters, and will appear on your customer's statement in capital letters. Non-ASCII characters are automatically stripped.
    #  It must contain at least one letter. Only used for subscription payments.
    attr_accessor :statement_descriptor
    # A [tax code](https://stripe.com/docs/tax/tax-categories) ID.
    attr_accessor :tax_code
    # The type of the product. Defaults to `service` if not explicitly specified, enabling use of this product with Subscriptions and Plans. Set this parameter to `good` to use this product with Orders and SKUs. On API versions before `2018-02-05`, this field defaults to `good` for compatibility reasons.
    attr_accessor :type
    # A label that represents units of this product. When set, this will be included in customers' receipts, invoices, Checkout, and the customer portal.
    attr_accessor :unit_label
    # A URL of a publicly-accessible webpage for this product.
    attr_accessor :url

    def initialize(
      active: nil,
      default_price_data: nil,
      description: nil,
      expand: nil,
      id: nil,
      images: nil,
      marketing_features: nil,
      metadata: nil,
      name: nil,
      package_dimensions: nil,
      shippable: nil,
      statement_descriptor: nil,
      tax_code: nil,
      type: nil,
      unit_label: nil,
      url: nil
    )
      @active = active
      @default_price_data = default_price_data
      @description = description
      @expand = expand
      @id = id
      @images = images
      @marketing_features = marketing_features
      @metadata = metadata
      @name = name
      @package_dimensions = package_dimensions
      @shippable = shippable
      @statement_descriptor = statement_descriptor
      @tax_code = tax_code
      @type = type
      @unit_label = unit_label
      @url = url
    end
  end
end
