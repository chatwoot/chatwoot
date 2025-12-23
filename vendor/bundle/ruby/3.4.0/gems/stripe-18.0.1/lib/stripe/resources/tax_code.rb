# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  # [Tax codes](https://stripe.com/docs/tax/tax-categories) classify goods and services for tax purposes.
  class TaxCode < APIResource
    extend Stripe::APIOperations::List

    OBJECT_NAME = "tax_code"
    def self.object_name
      "tax_code"
    end

    # A detailed description of which types of products the tax code represents.
    attr_reader :description
    # Unique identifier for the object.
    attr_reader :id
    # A short name for the tax code.
    attr_reader :name
    # String representing the object's type. Objects of the same type share the same value.
    attr_reader :object

    # A list of [all tax codes available](https://stripe.com/docs/tax/tax-categories) to add to Products in order to allow specific tax calculations.
    def self.list(params = {}, opts = {})
      request_stripe_object(method: :get, path: "/v1/tax_codes", params: params, opts: opts)
    end

    def self.inner_class_types
      @inner_class_types = {}
    end

    def self.field_remappings
      @field_remappings = {}
    end
  end
end
