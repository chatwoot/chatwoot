# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  # Tax rates can be applied to [invoices](https://docs.stripe.com/invoicing/taxes/tax-rates), [subscriptions](https://docs.stripe.com/billing/taxes/tax-rates) and [Checkout Sessions](https://docs.stripe.com/payments/checkout/use-manual-tax-rates) to collect tax.
  #
  # Related guide: [Tax rates](https://docs.stripe.com/billing/taxes/tax-rates)
  class TaxRate < APIResource
    extend Stripe::APIOperations::Create
    extend Stripe::APIOperations::List
    include Stripe::APIOperations::Save

    OBJECT_NAME = "tax_rate"
    def self.object_name
      "tax_rate"
    end

    class FlatAmount < ::Stripe::StripeObject
      # Amount of the tax when the `rate_type` is `flat_amount`. This positive integer represents how much to charge in the smallest currency unit (e.g., 100 cents to charge $1.00 or 100 to charge ¥100, a zero-decimal currency). The amount value supports up to eight digits (e.g., a value of 99999999 for a USD charge of $999,999.99).
      attr_reader :amount
      # Three-letter ISO currency code, in lowercase.
      attr_reader :currency

      def self.inner_class_types
        @inner_class_types = {}
      end

      def self.field_remappings
        @field_remappings = {}
      end
    end
    # Defaults to `true`. When set to `false`, this tax rate cannot be used with new applications or Checkout Sessions, but will still work for subscriptions and invoices that already have it set.
    attr_reader :active
    # Two-letter country code ([ISO 3166-1 alpha-2](https://en.wikipedia.org/wiki/ISO_3166-1_alpha-2)).
    attr_reader :country
    # Time at which the object was created. Measured in seconds since the Unix epoch.
    attr_reader :created
    # An arbitrary string attached to the tax rate for your internal use only. It will not be visible to your customers.
    attr_reader :description
    # The display name of the tax rates as it will appear to your customer on their receipt email, PDF, and the hosted invoice page.
    attr_reader :display_name
    # Actual/effective tax rate percentage out of 100. For tax calculations with automatic_tax[enabled]=true,
    # this percentage reflects the rate actually used to calculate tax based on the product's taxability
    # and whether the user is registered to collect taxes in the corresponding jurisdiction.
    attr_reader :effective_percentage
    # The amount of the tax rate when the `rate_type` is `flat_amount`. Tax rates with `rate_type` `percentage` can vary based on the transaction, resulting in this field being `null`. This field exposes the amount and currency of the flat tax rate.
    attr_reader :flat_amount
    # Unique identifier for the object.
    attr_reader :id
    # This specifies if the tax rate is inclusive or exclusive.
    attr_reader :inclusive
    # The jurisdiction for the tax rate. You can use this label field for tax reporting purposes. It also appears on your customer’s invoice.
    attr_reader :jurisdiction
    # The level of the jurisdiction that imposes this tax rate. Will be `null` for manually defined tax rates.
    attr_reader :jurisdiction_level
    # Has the value `true` if the object exists in live mode or the value `false` if the object exists in test mode.
    attr_reader :livemode
    # Set of [key-value pairs](https://stripe.com/docs/api/metadata) that you can attach to an object. This can be useful for storing additional information about the object in a structured format.
    attr_reader :metadata
    # String representing the object's type. Objects of the same type share the same value.
    attr_reader :object
    # Tax rate percentage out of 100. For tax calculations with automatic_tax[enabled]=true, this percentage includes the statutory tax rate of non-taxable jurisdictions.
    attr_reader :percentage
    # Indicates the type of tax rate applied to the taxable amount. This value can be `null` when no tax applies to the location. This field is only present for TaxRates created by Stripe Tax.
    attr_reader :rate_type
    # [ISO 3166-2 subdivision code](https://en.wikipedia.org/wiki/ISO_3166-2), without country prefix. For example, "NY" for New York, United States.
    attr_reader :state
    # The high-level tax type, such as `vat` or `sales_tax`.
    attr_reader :tax_type

    # Creates a new tax rate.
    def self.create(params = {}, opts = {})
      request_stripe_object(method: :post, path: "/v1/tax_rates", params: params, opts: opts)
    end

    # Returns a list of your tax rates. Tax rates are returned sorted by creation date, with the most recently created tax rates appearing first.
    def self.list(params = {}, opts = {})
      request_stripe_object(method: :get, path: "/v1/tax_rates", params: params, opts: opts)
    end

    # Updates an existing tax rate.
    def self.update(tax_rate, params = {}, opts = {})
      request_stripe_object(
        method: :post,
        path: format("/v1/tax_rates/%<tax_rate>s", { tax_rate: CGI.escape(tax_rate) }),
        params: params,
        opts: opts
      )
    end

    def self.inner_class_types
      @inner_class_types = { flat_amount: FlatAmount }
    end

    def self.field_remappings
      @field_remappings = {}
    end
  end
end
