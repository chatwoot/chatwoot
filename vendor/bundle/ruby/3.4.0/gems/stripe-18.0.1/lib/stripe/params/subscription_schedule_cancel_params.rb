# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  class SubscriptionScheduleCancelParams < ::Stripe::RequestParams
    # Specifies which fields in the response should be expanded.
    attr_accessor :expand
    # If the subscription schedule is `active`, indicates if a final invoice will be generated that contains any un-invoiced metered usage and new/pending proration invoice items. Defaults to `true`.
    attr_accessor :invoice_now
    # If the subscription schedule is `active`, indicates if the cancellation should be prorated. Defaults to `true`.
    attr_accessor :prorate

    def initialize(expand: nil, invoice_now: nil, prorate: nil)
      @expand = expand
      @invoice_now = invoice_now
      @prorate = prorate
    end
  end
end
