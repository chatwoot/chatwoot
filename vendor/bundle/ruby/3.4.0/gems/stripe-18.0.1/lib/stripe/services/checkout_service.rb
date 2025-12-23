# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  class CheckoutService < StripeService
    attr_reader :sessions

    def initialize(requestor)
      super
      @sessions = Stripe::Checkout::SessionService.new(@requestor)
    end
  end
end
