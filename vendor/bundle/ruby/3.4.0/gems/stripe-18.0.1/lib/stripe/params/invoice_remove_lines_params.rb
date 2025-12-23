# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  class InvoiceRemoveLinesParams < ::Stripe::RequestParams
    class Line < ::Stripe::RequestParams
      # Either `delete` or `unassign`. Deleted line items are permanently deleted. Unassigned line items can be reassigned to an invoice.
      attr_accessor :behavior
      # ID of an existing line item to remove from this invoice.
      attr_accessor :id

      def initialize(behavior: nil, id: nil)
        @behavior = behavior
        @id = id
      end
    end
    # Specifies which fields in the response should be expanded.
    attr_accessor :expand
    # Set of [key-value pairs](https://stripe.com/docs/api/metadata) that you can attach to an object. This can be useful for storing additional information about the object in a structured format. Individual keys can be unset by posting an empty value to them. All keys can be unset by posting an empty value to `metadata`.
    attr_accessor :invoice_metadata
    # The line items to remove.
    attr_accessor :lines

    def initialize(expand: nil, invoice_metadata: nil, lines: nil)
      @expand = expand
      @invoice_metadata = invoice_metadata
      @lines = lines
    end
  end
end
