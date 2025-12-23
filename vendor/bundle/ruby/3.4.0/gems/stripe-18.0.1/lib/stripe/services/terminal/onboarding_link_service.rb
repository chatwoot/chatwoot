# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  module Terminal
    class OnboardingLinkService < StripeService
      # Creates a new OnboardingLink object that contains a redirect_url used for onboarding onto Tap to Pay on iPhone.
      def create(params = {}, opts = {})
        request(
          method: :post,
          path: "/v1/terminal/onboarding_links",
          params: params,
          opts: opts,
          base_address: :api
        )
      end
    end
  end
end
