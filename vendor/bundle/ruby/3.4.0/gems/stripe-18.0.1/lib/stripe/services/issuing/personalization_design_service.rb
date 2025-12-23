# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  module Issuing
    class PersonalizationDesignService < StripeService
      # Creates a personalization design object.
      def create(params = {}, opts = {})
        request(
          method: :post,
          path: "/v1/issuing/personalization_designs",
          params: params,
          opts: opts,
          base_address: :api
        )
      end

      # Returns a list of personalization design objects. The objects are sorted in descending order by creation date, with the most recently created object appearing first.
      def list(params = {}, opts = {})
        request(
          method: :get,
          path: "/v1/issuing/personalization_designs",
          params: params,
          opts: opts,
          base_address: :api
        )
      end

      # Retrieves a personalization design object.
      def retrieve(personalization_design, params = {}, opts = {})
        request(
          method: :get,
          path: format("/v1/issuing/personalization_designs/%<personalization_design>s", { personalization_design: CGI.escape(personalization_design) }),
          params: params,
          opts: opts,
          base_address: :api
        )
      end

      # Updates a card personalization object.
      def update(personalization_design, params = {}, opts = {})
        request(
          method: :post,
          path: format("/v1/issuing/personalization_designs/%<personalization_design>s", { personalization_design: CGI.escape(personalization_design) }),
          params: params,
          opts: opts,
          base_address: :api
        )
      end
    end
  end
end
