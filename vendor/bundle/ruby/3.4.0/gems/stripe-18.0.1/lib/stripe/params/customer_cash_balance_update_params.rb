# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  class CustomerCashBalanceUpdateParams < ::Stripe::RequestParams
    class Settings < ::Stripe::RequestParams
      # Controls how funds transferred by the customer are applied to payment intents and invoices. Valid options are `automatic`, `manual`, or `merchant_default`. For more information about these reconciliation modes, see [Reconciliation](https://stripe.com/docs/payments/customer-balance/reconciliation).
      attr_accessor :reconciliation_mode

      def initialize(reconciliation_mode: nil)
        @reconciliation_mode = reconciliation_mode
      end
    end
    # Specifies which fields in the response should be expanded.
    attr_accessor :expand
    # A hash of settings for this cash balance.
    attr_accessor :settings

    def initialize(expand: nil, settings: nil)
      @expand = expand
      @settings = settings
    end
  end
end
