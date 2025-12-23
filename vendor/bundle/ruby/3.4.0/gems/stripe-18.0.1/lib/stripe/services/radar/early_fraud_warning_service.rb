# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  module Radar
    class EarlyFraudWarningService < StripeService
      # Returns a list of early fraud warnings.
      def list(params = {}, opts = {})
        request(
          method: :get,
          path: "/v1/radar/early_fraud_warnings",
          params: params,
          opts: opts,
          base_address: :api
        )
      end

      # Retrieves the details of an early fraud warning that has previously been created.
      #
      # Please refer to the [early fraud warning](https://docs.stripe.com/api#early_fraud_warning_object) object reference for more details.
      def retrieve(early_fraud_warning, params = {}, opts = {})
        request(
          method: :get,
          path: format("/v1/radar/early_fraud_warnings/%<early_fraud_warning>s", { early_fraud_warning: CGI.escape(early_fraud_warning) }),
          params: params,
          opts: opts,
          base_address: :api
        )
      end
    end
  end
end
