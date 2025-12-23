# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  class AccountCapabilityUpdateParams < ::Stripe::RequestParams
    # Specifies which fields in the response should be expanded.
    attr_accessor :expand
    # To request a new capability for an account, pass true. There can be a delay before the requested capability becomes active. If the capability has any activation requirements, the response includes them in the `requirements` arrays.
    #
    # If a capability isn't permanent, you can remove it from the account by passing false. Some capabilities are permanent after they've been requested. Attempting to remove a permanent capability returns an error.
    attr_accessor :requested

    def initialize(expand: nil, requested: nil)
      @expand = expand
      @requested = requested
    end
  end
end
