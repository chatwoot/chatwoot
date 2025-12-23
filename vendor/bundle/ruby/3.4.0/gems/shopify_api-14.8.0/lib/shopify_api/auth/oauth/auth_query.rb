# typed: strict
# frozen_string_literal: true

module ShopifyAPI
  module Auth
    module Oauth
      class AuthQuery
        extend T::Sig
        include Utils::VerifiableQuery

        sig { returns(String) }
        attr_reader :code, :host, :hmac, :shop, :state, :timestamp

        sig do
          params(
            code: String,
            shop: String,
            timestamp: String,
            state: String,
            host: String,
            hmac: String,
          ).void
        end
        def initialize(code:, shop:, timestamp:, state:, host:, hmac:)
          @code = code
          @shop = shop
          @timestamp = timestamp
          @state = state
          @host = host
          @hmac = hmac
        end

        sig { override.returns(String) }
        def to_signable_string
          params = {
            code: code,
            host: host,
            shop: shop,
            state: state,
            timestamp: timestamp,
          }
          URI.encode_www_form(params)
        end
      end
    end
  end
end
