# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  module TestHelpers
    module Issuing
      class AuthorizationService < StripeService
        # Capture a test-mode authorization.
        def capture(authorization, params = {}, opts = {})
          request(
            method: :post,
            path: format("/v1/test_helpers/issuing/authorizations/%<authorization>s/capture", { authorization: CGI.escape(authorization) }),
            params: params,
            opts: opts,
            base_address: :api
          )
        end

        # Create a test-mode authorization.
        def create(params = {}, opts = {})
          request(
            method: :post,
            path: "/v1/test_helpers/issuing/authorizations",
            params: params,
            opts: opts,
            base_address: :api
          )
        end

        # Expire a test-mode Authorization.
        def expire(authorization, params = {}, opts = {})
          request(
            method: :post,
            path: format("/v1/test_helpers/issuing/authorizations/%<authorization>s/expire", { authorization: CGI.escape(authorization) }),
            params: params,
            opts: opts,
            base_address: :api
          )
        end

        # Finalize the amount on an Authorization prior to capture, when the initial authorization was for an estimated amount.
        def finalize_amount(authorization, params = {}, opts = {})
          request(
            method: :post,
            path: format("/v1/test_helpers/issuing/authorizations/%<authorization>s/finalize_amount", { authorization: CGI.escape(authorization) }),
            params: params,
            opts: opts,
            base_address: :api
          )
        end

        # Increment a test-mode Authorization.
        def increment(authorization, params = {}, opts = {})
          request(
            method: :post,
            path: format("/v1/test_helpers/issuing/authorizations/%<authorization>s/increment", { authorization: CGI.escape(authorization) }),
            params: params,
            opts: opts,
            base_address: :api
          )
        end

        # Respond to a fraud challenge on a testmode Issuing authorization, simulating either a confirmation of fraud or a correction of legitimacy.
        def respond(authorization, params = {}, opts = {})
          request(
            method: :post,
            path: format("/v1/test_helpers/issuing/authorizations/%<authorization>s/fraud_challenges/respond", { authorization: CGI.escape(authorization) }),
            params: params,
            opts: opts,
            base_address: :api
          )
        end

        # Reverse a test-mode Authorization.
        def reverse(authorization, params = {}, opts = {})
          request(
            method: :post,
            path: format("/v1/test_helpers/issuing/authorizations/%<authorization>s/reverse", { authorization: CGI.escape(authorization) }),
            params: params,
            opts: opts,
            base_address: :api
          )
        end
      end
    end
  end
end
