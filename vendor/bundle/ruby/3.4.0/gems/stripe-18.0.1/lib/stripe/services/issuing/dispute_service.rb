# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  module Issuing
    class DisputeService < StripeService
      # Creates an Issuing Dispute object. Individual pieces of evidence within the evidence object are optional at this point. Stripe only validates that required evidence is present during submission. Refer to [Dispute reasons and evidence](https://docs.stripe.com/docs/issuing/purchases/disputes#dispute-reasons-and-evidence) for more details about evidence requirements.
      def create(params = {}, opts = {})
        request(
          method: :post,
          path: "/v1/issuing/disputes",
          params: params,
          opts: opts,
          base_address: :api
        )
      end

      # Returns a list of Issuing Dispute objects. The objects are sorted in descending order by creation date, with the most recently created object appearing first.
      def list(params = {}, opts = {})
        request(
          method: :get,
          path: "/v1/issuing/disputes",
          params: params,
          opts: opts,
          base_address: :api
        )
      end

      # Retrieves an Issuing Dispute object.
      def retrieve(dispute, params = {}, opts = {})
        request(
          method: :get,
          path: format("/v1/issuing/disputes/%<dispute>s", { dispute: CGI.escape(dispute) }),
          params: params,
          opts: opts,
          base_address: :api
        )
      end

      # Submits an Issuing Dispute to the card network. Stripe validates that all evidence fields required for the dispute's reason are present. For more details, see [Dispute reasons and evidence](https://docs.stripe.com/docs/issuing/purchases/disputes#dispute-reasons-and-evidence).
      def submit(dispute, params = {}, opts = {})
        request(
          method: :post,
          path: format("/v1/issuing/disputes/%<dispute>s/submit", { dispute: CGI.escape(dispute) }),
          params: params,
          opts: opts,
          base_address: :api
        )
      end

      # Updates the specified Issuing Dispute object by setting the values of the parameters passed. Any parameters not provided will be left unchanged. Properties on the evidence object can be unset by passing in an empty string.
      def update(dispute, params = {}, opts = {})
        request(
          method: :post,
          path: format("/v1/issuing/disputes/%<dispute>s", { dispute: CGI.escape(dispute) }),
          params: params,
          opts: opts,
          base_address: :api
        )
      end
    end
  end
end
