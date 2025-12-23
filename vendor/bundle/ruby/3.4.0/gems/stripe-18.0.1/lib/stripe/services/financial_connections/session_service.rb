# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  module FinancialConnections
    class SessionService < StripeService
      # To launch the Financial Connections authorization flow, create a Session. The session's client_secret can be used to launch the flow using Stripe.js.
      def create(params = {}, opts = {})
        request(
          method: :post,
          path: "/v1/financial_connections/sessions",
          params: params,
          opts: opts,
          base_address: :api
        )
      end

      # Retrieves the details of a Financial Connections Session
      def retrieve(session, params = {}, opts = {})
        request(
          method: :get,
          path: format("/v1/financial_connections/sessions/%<session>s", { session: CGI.escape(session) }),
          params: params,
          opts: opts,
          base_address: :api
        )
      end
    end
  end
end
