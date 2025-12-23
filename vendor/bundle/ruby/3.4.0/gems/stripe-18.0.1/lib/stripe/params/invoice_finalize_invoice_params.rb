# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  class InvoiceFinalizeInvoiceParams < ::Stripe::RequestParams
    # Controls whether Stripe performs [automatic collection](https://stripe.com/docs/invoicing/integration/automatic-advancement-collection) of the invoice. If `false`, the invoice's state doesn't automatically advance without an explicit action.
    attr_accessor :auto_advance
    # Specifies which fields in the response should be expanded.
    attr_accessor :expand

    def initialize(auto_advance: nil, expand: nil)
      @auto_advance = auto_advance
      @expand = expand
    end
  end
end
