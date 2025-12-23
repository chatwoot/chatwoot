# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  module Tax
    class CalculationLineItemService < StripeService
      # Retrieves the line items of a tax calculation as a collection, if the calculation hasn't expired.
      def list(calculation, params = {}, opts = {})
        request(
          method: :get,
          path: format("/v1/tax/calculations/%<calculation>s/line_items", { calculation: CGI.escape(calculation) }),
          params: params,
          opts: opts,
          base_address: :api
        )
      end
    end
  end
end
