# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  class PaymentRecordReportPaymentAttemptCanceledParams < ::Stripe::RequestParams
    # When the reported payment was canceled. Measured in seconds since the Unix epoch.
    attr_accessor :canceled_at
    # Specifies which fields in the response should be expanded.
    attr_accessor :expand
    # Attribute for param field metadata
    attr_accessor :metadata

    def initialize(canceled_at: nil, expand: nil, metadata: nil)
      @canceled_at = canceled_at
      @expand = expand
      @metadata = metadata
    end
  end
end
