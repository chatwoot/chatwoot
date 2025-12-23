# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  class ForwardingService < StripeService
    attr_reader :requests

    def initialize(requestor)
      super
      @requests = Stripe::Forwarding::RequestService.new(@requestor)
    end
  end
end
