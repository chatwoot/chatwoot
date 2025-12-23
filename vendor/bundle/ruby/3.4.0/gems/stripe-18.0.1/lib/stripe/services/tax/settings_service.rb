# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  module Tax
    class SettingsService < StripeService
      # Retrieves Tax Settings for a merchant.
      def retrieve(params = {}, opts = {})
        request(
          method: :get,
          path: "/v1/tax/settings",
          params: params,
          opts: opts,
          base_address: :api
        )
      end

      # Updates Tax Settings parameters used in tax calculations. All parameters are editable but none can be removed once set.
      def update(params = {}, opts = {})
        request(
          method: :post,
          path: "/v1/tax/settings",
          params: params,
          opts: opts,
          base_address: :api
        )
      end
    end
  end
end
