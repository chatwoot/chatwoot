# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  class TaxRateCreateParams < ::Stripe::RequestParams
    # Flag determining whether the tax rate is active or inactive (archived). Inactive tax rates cannot be used with new applications or Checkout Sessions, but will still work for subscriptions and invoices that already have it set.
    attr_accessor :active
    # Two-letter country code ([ISO 3166-1 alpha-2](https://en.wikipedia.org/wiki/ISO_3166-1_alpha-2)).
    attr_accessor :country
    # An arbitrary string attached to the tax rate for your internal use only. It will not be visible to your customers.
    attr_accessor :description
    # The display name of the tax rate, which will be shown to users.
    attr_accessor :display_name
    # Specifies which fields in the response should be expanded.
    attr_accessor :expand
    # This specifies if the tax rate is inclusive or exclusive.
    attr_accessor :inclusive
    # The jurisdiction for the tax rate. You can use this label field for tax reporting purposes. It also appears on your customer’s invoice.
    attr_accessor :jurisdiction
    # Set of [key-value pairs](https://stripe.com/docs/api/metadata) that you can attach to an object. This can be useful for storing additional information about the object in a structured format. Individual keys can be unset by posting an empty value to them. All keys can be unset by posting an empty value to `metadata`.
    attr_accessor :metadata
    # This represents the tax rate percent out of 100.
    attr_accessor :percentage
    # [ISO 3166-2 subdivision code](https://en.wikipedia.org/wiki/ISO_3166-2), without country prefix. For example, "NY" for New York, United States.
    attr_accessor :state
    # The high-level tax type, such as `vat` or `sales_tax`.
    attr_accessor :tax_type

    def initialize(
      active: nil,
      country: nil,
      description: nil,
      display_name: nil,
      expand: nil,
      inclusive: nil,
      jurisdiction: nil,
      metadata: nil,
      percentage: nil,
      state: nil,
      tax_type: nil
    )
      @active = active
      @country = country
      @description = description
      @display_name = display_name
      @expand = expand
      @inclusive = inclusive
      @jurisdiction = jurisdiction
      @metadata = metadata
      @percentage = percentage
      @state = state
      @tax_type = tax_type
    end
  end
end
