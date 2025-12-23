# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  class AccountRejectParams < ::Stripe::RequestParams
    # Specifies which fields in the response should be expanded.
    attr_accessor :expand
    # The reason for rejecting the account. Can be `fraud`, `terms_of_service`, or `other`.
    attr_accessor :reason

    def initialize(expand: nil, reason: nil)
      @expand = expand
      @reason = reason
    end
  end
end
