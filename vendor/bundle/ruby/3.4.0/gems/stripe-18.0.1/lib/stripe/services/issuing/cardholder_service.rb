# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  module Issuing
    class CardholderService < StripeService
      # Creates a new Issuing Cardholder object that can be issued cards.
      def create(params = {}, opts = {})
        request(
          method: :post,
          path: "/v1/issuing/cardholders",
          params: params,
          opts: opts,
          base_address: :api
        )
      end

      # Returns a list of Issuing Cardholder objects. The objects are sorted in descending order by creation date, with the most recently created object appearing first.
      def list(params = {}, opts = {})
        request(
          method: :get,
          path: "/v1/issuing/cardholders",
          params: params,
          opts: opts,
          base_address: :api
        )
      end

      # Retrieves an Issuing Cardholder object.
      def retrieve(cardholder, params = {}, opts = {})
        request(
          method: :get,
          path: format("/v1/issuing/cardholders/%<cardholder>s", { cardholder: CGI.escape(cardholder) }),
          params: params,
          opts: opts,
          base_address: :api
        )
      end

      # Updates the specified Issuing Cardholder object by setting the values of the parameters passed. Any parameters not provided will be left unchanged.
      def update(cardholder, params = {}, opts = {})
        request(
          method: :post,
          path: format("/v1/issuing/cardholders/%<cardholder>s", { cardholder: CGI.escape(cardholder) }),
          params: params,
          opts: opts,
          base_address: :api
        )
      end
    end
  end
end
