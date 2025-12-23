# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  class SubscriptionMigrateParams < ::Stripe::RequestParams
    class BillingMode < ::Stripe::RequestParams
      class Flexible < ::Stripe::RequestParams
        # Controls how invoices and invoice items display proration amounts and discount amounts.
        attr_accessor :proration_discounts

        def initialize(proration_discounts: nil)
          @proration_discounts = proration_discounts
        end
      end
      # Configure behavior for flexible billing mode.
      attr_accessor :flexible
      # Controls the calculation and orchestration of prorations and invoices for subscriptions.
      attr_accessor :type

      def initialize(flexible: nil, type: nil)
        @flexible = flexible
        @type = type
      end
    end
    # Controls how prorations and invoices for subscriptions are calculated and orchestrated.
    attr_accessor :billing_mode
    # Specifies which fields in the response should be expanded.
    attr_accessor :expand

    def initialize(billing_mode: nil, expand: nil)
      @billing_mode = billing_mode
      @expand = expand
    end
  end
end
