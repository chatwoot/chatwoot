# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  class PaymentRecordReportPaymentAttemptFailedParams < ::Stripe::RequestParams
    # Specifies which fields in the response should be expanded.
    attr_accessor :expand
    # When the reported payment failed. Measured in seconds since the Unix epoch.
    attr_accessor :failed_at
    # Attribute for param field metadata
    attr_accessor :metadata

    def initialize(expand: nil, failed_at: nil, metadata: nil)
      @expand = expand
      @failed_at = failed_at
      @metadata = metadata
    end
  end
end
