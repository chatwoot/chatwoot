# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  module Issuing
    class PhysicalBundleService < StripeService
      # Returns a list of physical bundle objects. The objects are sorted in descending order by creation date, with the most recently created object appearing first.
      def list(params = {}, opts = {})
        request(
          method: :get,
          path: "/v1/issuing/physical_bundles",
          params: params,
          opts: opts,
          base_address: :api
        )
      end

      # Retrieves a physical bundle object.
      def retrieve(physical_bundle, params = {}, opts = {})
        request(
          method: :get,
          path: format("/v1/issuing/physical_bundles/%<physical_bundle>s", { physical_bundle: CGI.escape(physical_bundle) }),
          params: params,
          opts: opts,
          base_address: :api
        )
      end
    end
  end
end
