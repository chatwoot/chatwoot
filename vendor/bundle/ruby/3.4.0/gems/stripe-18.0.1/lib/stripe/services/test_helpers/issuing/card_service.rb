# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  module TestHelpers
    module Issuing
      class CardService < StripeService
        # Updates the shipping status of the specified Issuing Card object to delivered.
        def deliver_card(card, params = {}, opts = {})
          request(
            method: :post,
            path: format("/v1/test_helpers/issuing/cards/%<card>s/shipping/deliver", { card: CGI.escape(card) }),
            params: params,
            opts: opts,
            base_address: :api
          )
        end

        # Updates the shipping status of the specified Issuing Card object to failure.
        def fail_card(card, params = {}, opts = {})
          request(
            method: :post,
            path: format("/v1/test_helpers/issuing/cards/%<card>s/shipping/fail", { card: CGI.escape(card) }),
            params: params,
            opts: opts,
            base_address: :api
          )
        end

        # Updates the shipping status of the specified Issuing Card object to returned.
        def return_card(card, params = {}, opts = {})
          request(
            method: :post,
            path: format("/v1/test_helpers/issuing/cards/%<card>s/shipping/return", { card: CGI.escape(card) }),
            params: params,
            opts: opts,
            base_address: :api
          )
        end

        # Updates the shipping status of the specified Issuing Card object to shipped.
        def ship_card(card, params = {}, opts = {})
          request(
            method: :post,
            path: format("/v1/test_helpers/issuing/cards/%<card>s/shipping/ship", { card: CGI.escape(card) }),
            params: params,
            opts: opts,
            base_address: :api
          )
        end

        # Updates the shipping status of the specified Issuing Card object to submitted. This method requires Stripe Version ‘2024-09-30.acacia' or later.
        def submit_card(card, params = {}, opts = {})
          request(
            method: :post,
            path: format("/v1/test_helpers/issuing/cards/%<card>s/shipping/submit", { card: CGI.escape(card) }),
            params: params,
            opts: opts,
            base_address: :api
          )
        end
      end
    end
  end
end
