# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  module Tax
    class CalculationService < StripeService
      attr_reader :line_items

      def initialize(requestor)
        super
        @line_items = Stripe::Tax::CalculationLineItemService.new(@requestor)
      end

      # Calculates tax based on the input and returns a Tax Calculation object.
      def create(params = {}, opts = {})
        request(
          method: :post,
          path: "/v1/tax/calculations",
          params: params,
          opts: opts,
          base_address: :api
        )
      end

      # Retrieves a Tax Calculation object, if the calculation hasn't expired.
      def retrieve(calculation, params = {}, opts = {})
        request(
          method: :get,
          path: format("/v1/tax/calculations/%<calculation>s", { calculation: CGI.escape(calculation) }),
          params: params,
          opts: opts,
          base_address: :api
        )
      end
    end
  end
end
