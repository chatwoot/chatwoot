# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  class TaxDeductedAtSource < APIResource
    OBJECT_NAME = "tax_deducted_at_source"
    def self.object_name
      "tax_deducted_at_source"
    end

    # Unique identifier for the object.
    attr_reader :id
    # String representing the object's type. Objects of the same type share the same value.
    attr_reader :object
    # The end of the invoicing period. This TDS applies to Stripe fees collected during this invoicing period.
    attr_reader :period_end
    # The start of the invoicing period. This TDS applies to Stripe fees collected during this invoicing period.
    attr_reader :period_start
    # The TAN that was supplied to Stripe when TDS was assessed
    attr_reader :tax_deduction_account_number

    def self.inner_class_types
      @inner_class_types = {}
    end

    def self.field_remappings
      @field_remappings = {}
    end
  end
end
