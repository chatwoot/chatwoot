# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  class ReserveTransaction < APIResource
    OBJECT_NAME = "reserve_transaction"
    def self.object_name
      "reserve_transaction"
    end

    # Attribute for field amount
    attr_reader :amount
    # Three-letter [ISO currency code](https://www.iso.org/iso-4217-currency-codes.html), in lowercase. Must be a [supported currency](https://stripe.com/docs/currencies).
    attr_reader :currency
    # An arbitrary string attached to the object. Often useful for displaying to users.
    attr_reader :description
    # Unique identifier for the object.
    attr_reader :id
    # String representing the object's type. Objects of the same type share the same value.
    attr_reader :object

    def self.inner_class_types
      @inner_class_types = {}
    end

    def self.field_remappings
      @field_remappings = {}
    end
  end
end
