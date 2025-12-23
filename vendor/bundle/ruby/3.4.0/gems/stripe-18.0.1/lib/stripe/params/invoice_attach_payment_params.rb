# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  class InvoiceAttachPaymentParams < ::Stripe::RequestParams
    # Specifies which fields in the response should be expanded.
    attr_accessor :expand
    # The ID of the PaymentIntent to attach to the invoice.
    attr_accessor :payment_intent
    # The ID of the PaymentRecord to attach to the invoice.
    attr_accessor :payment_record

    def initialize(expand: nil, payment_intent: nil, payment_record: nil)
      @expand = expand
      @payment_intent = payment_intent
      @payment_record = payment_record
    end
  end
end
