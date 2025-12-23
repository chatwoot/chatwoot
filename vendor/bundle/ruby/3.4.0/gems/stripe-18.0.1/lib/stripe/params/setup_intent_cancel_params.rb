# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  class SetupIntentCancelParams < ::Stripe::RequestParams
    # Reason for canceling this SetupIntent. Possible values are: `abandoned`, `requested_by_customer`, or `duplicate`
    attr_accessor :cancellation_reason
    # Specifies which fields in the response should be expanded.
    attr_accessor :expand

    def initialize(cancellation_reason: nil, expand: nil)
      @cancellation_reason = cancellation_reason
      @expand = expand
    end
  end
end
