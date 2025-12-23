# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  module TestHelpers
    module Issuing
      class PersonalizationDesignService < StripeService
        # Updates the status of the specified testmode personalization design object to active.
        def activate(personalization_design, params = {}, opts = {})
          request(
            method: :post,
            path: format("/v1/test_helpers/issuing/personalization_designs/%<personalization_design>s/activate", { personalization_design: CGI.escape(personalization_design) }),
            params: params,
            opts: opts,
            base_address: :api
          )
        end

        # Updates the status of the specified testmode personalization design object to inactive.
        def deactivate(personalization_design, params = {}, opts = {})
          request(
            method: :post,
            path: format("/v1/test_helpers/issuing/personalization_designs/%<personalization_design>s/deactivate", { personalization_design: CGI.escape(personalization_design) }),
            params: params,
            opts: opts,
            base_address: :api
          )
        end

        # Updates the status of the specified testmode personalization design object to rejected.
        def reject(personalization_design, params = {}, opts = {})
          request(
            method: :post,
            path: format("/v1/test_helpers/issuing/personalization_designs/%<personalization_design>s/reject", { personalization_design: CGI.escape(personalization_design) }),
            params: params,
            opts: opts,
            base_address: :api
          )
        end
      end
    end
  end
end
