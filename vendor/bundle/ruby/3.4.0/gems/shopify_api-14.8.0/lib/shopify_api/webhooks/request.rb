# typed: strict
# frozen_string_literal: true

module ShopifyAPI
  module Webhooks
    class Request
      extend T::Sig
      include Utils::VerifiableQuery

      sig { override.returns(String) }
      def hmac
        Digest.hexencode(Base64.decode64(T.cast(@headers["x-shopify-hmac-sha256"], String)))
      end

      sig { returns(String) }
      def topic
        T.cast(@headers["x-shopify-topic"], String)
      end

      sig { returns(String) }
      def shop
        T.cast(@headers["x-shopify-shop-domain"], String)
      end

      sig { returns(String) }
      def api_version
        T.cast(@headers["x-shopify-api-version"], String)
      end

      sig { returns(String) }
      def webhook_id
        T.cast(@headers["x-shopify-webhook-id"], String)
      end

      sig { override.returns(String) }
      def to_signable_string
        @raw_body
      end

      sig { returns(T::Hash[String, T.untyped]) }
      def parsed_body
        JSON.parse(@raw_body)
      end

      sig { params(raw_body: String, headers: T::Hash[String, T.untyped]).void }
      def initialize(raw_body:, headers:)
        # normalize the headers by forcing lowercase, removing any prepended "http"s, and changing underscores to dashes
        headers = headers.to_h { |k, v| [k.to_s.downcase.sub("http_", "").gsub("_", "-"), v] }

        missing_headers = []
        [
          "x-shopify-topic",
          "x-shopify-hmac-sha256",
          "x-shopify-shop-domain",
        ].each { |header| missing_headers << header unless headers.include?(header) }
        unless missing_headers.empty?
          raise Errors::InvalidWebhookError,
            "Missing one or more of the required HTTP headers to process webhooks: #{missing_headers}"
        end

        @headers = headers
        @raw_body = raw_body
      end
    end
  end
end
