# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  module Issuing
    class CardService < StripeService
      # Creates an Issuing Card object.
      def create(params = {}, opts = {})
        request(
          method: :post,
          path: "/v1/issuing/cards",
          params: params,
          opts: opts,
          base_address: :api
        )
      end

      # Returns a list of Issuing Card objects. The objects are sorted in descending order by creation date, with the most recently created object appearing first.
      def list(params = {}, opts = {})
        request(
          method: :get,
          path: "/v1/issuing/cards",
          params: params,
          opts: opts,
          base_address: :api
        )
      end

      # Retrieves an Issuing Card object.
      def retrieve(card, params = {}, opts = {})
        request(
          method: :get,
          path: format("/v1/issuing/cards/%<card>s", { card: CGI.escape(card) }),
          params: params,
          opts: opts,
          base_address: :api
        )
      end

      # Updates the specified Issuing Card object by setting the values of the parameters passed. Any parameters not provided will be left unchanged.
      def update(card, params = {}, opts = {})
        request(
          method: :post,
          path: format("/v1/issuing/cards/%<card>s", { card: CGI.escape(card) }),
          params: params,
          opts: opts,
          base_address: :api
        )
      end
    end
  end
end
