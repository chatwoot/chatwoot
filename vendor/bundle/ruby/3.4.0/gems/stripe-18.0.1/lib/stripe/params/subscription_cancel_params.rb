# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  class SubscriptionCancelParams < ::Stripe::RequestParams
    class CancellationDetails < ::Stripe::RequestParams
      # Additional comments about why the user canceled the subscription, if the subscription was canceled explicitly by the user.
      attr_accessor :comment
      # The customer submitted reason for why they canceled, if the subscription was canceled explicitly by the user.
      attr_accessor :feedback

      def initialize(comment: nil, feedback: nil)
        @comment = comment
        @feedback = feedback
      end
    end
    # Details about why this subscription was cancelled
    attr_accessor :cancellation_details
    # Specifies which fields in the response should be expanded.
    attr_accessor :expand
    # Will generate a final invoice that invoices for any un-invoiced metered usage and new/pending proration invoice items. Defaults to `false`.
    attr_accessor :invoice_now
    # Will generate a proration invoice item that credits remaining unused time until the subscription period end. Defaults to `false`.
    attr_accessor :prorate

    def initialize(cancellation_details: nil, expand: nil, invoice_now: nil, prorate: nil)
      @cancellation_details = cancellation_details
      @expand = expand
      @invoice_now = invoice_now
      @prorate = prorate
    end
  end
end
