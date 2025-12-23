# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  class ApplicationFeeService < StripeService
    attr_reader :refunds

    def initialize(requestor)
      super
      @refunds = Stripe::ApplicationFeeRefundService.new(@requestor)
    end

    # Returns a list of application fees you've previously collected. The application fees are returned in sorted order, with the most recent fees appearing first.
    def list(params = {}, opts = {})
      request(
        method: :get,
        path: "/v1/application_fees",
        params: params,
        opts: opts,
        base_address: :api
      )
    end

    # Retrieves the details of an application fee that your account has collected. The same information is returned when refunding the application fee.
    def retrieve(id, params = {}, opts = {})
      request(
        method: :get,
        path: format("/v1/application_fees/%<id>s", { id: CGI.escape(id) }),
        params: params,
        opts: opts,
        base_address: :api
      )
    end
  end
end
