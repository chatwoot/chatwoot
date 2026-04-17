# frozen_string_literal: true

require 'net/http'
require 'json'
require 'openssl'

module Igaralead
  # Validates Hub JWT access tokens using the SSO JWKS endpoint.
  #
  # Flow:
  #   1. Fetch JWKS from SSO_URL/jwks (cached in-memory for 1 hour)
  #   2. Decode and verify the JWT signature (RS256) using the matching key
  #   3. Verify issuer, audience, and expiration
  #   4. Return the decoded payload or nil on failure
  #
  # Falls back to HS256 validation against SECRET_KEY_BASE when SSO JWKS
  # is unavailable, allowing direct Hub-signed tokens to work too.
  class HubTokenValidator
    JWKS_CACHE_TTL = 3600 # 1 hour
    EXPECTED_ISSUER = 'igaralead'
    EXPECTED_AUDIENCE = 'igaralead'

    class << self
      def validate(token)
        return nil if token.blank?

        payload = decode_with_jwks(token)
        payload ||= decode_with_shared_secret(token)
        return nil unless payload

        # Verify claims
        return nil if payload['exp'].present? && Time.at(payload['exp'].to_i) < Time.current
        return nil if payload['iss'].present? && payload['iss'] != EXPECTED_ISSUER
        return nil if payload['aud'].present? && payload['aud'] != EXPECTED_AUDIENCE

        payload
      rescue StandardError => e
        Rails.logger.warn("[Igaralead::HubTokenValidator] Validation failed: #{e.message}")
        nil
      end

      private

      def decode_with_jwks(token)
        jwks = fetch_jwks
        return nil if jwks.blank?

        # Decode the header to find the kid
        header_segment = token.split('.').first
        header = JSON.parse(Base64.urlsafe_decode64(header_segment + '=' * (4 - header_segment.length % 4)))
        kid = header['kid']
        alg = header['alg'] || 'RS256'

        return nil unless alg == 'RS256'

        # Find the matching key
        key_data = jwks['keys']&.find { |k| k['kid'] == kid }
        return nil unless key_data

        # Build RSA public key from JWK
        rsa_key = build_rsa_key(key_data)
        return nil unless rsa_key

        # Verify and decode
        segments = token.split('.')
        return nil unless segments.length == 3

        signing_input = "#{segments[0]}.#{segments[1]}"
        signature = Base64.urlsafe_decode64(segments[2] + '=' * (4 - segments[2].length % 4))

        return nil unless rsa_key.verify(OpenSSL::Digest.new('SHA256'), signature, signing_input)

        payload_segment = segments[1]
        JSON.parse(Base64.urlsafe_decode64(payload_segment + '=' * (4 - payload_segment.length % 4)))
      rescue StandardError => e
        Rails.logger.debug("[Igaralead::HubTokenValidator] JWKS decode failed: #{e.message}")
        nil
      end

      def decode_with_shared_secret(token)
        secret = Rails.application.secret_key_base
        return nil if secret.blank?

        segments = token.split('.')
        return nil unless segments.length == 3

        # Check if it's HS256
        header_segment = segments[0]
        header = JSON.parse(Base64.urlsafe_decode64(header_segment + '=' * (4 - header_segment.length % 4)))
        return nil unless header['alg'] == 'HS256'

        # Verify HMAC
        signing_input = "#{segments[0]}.#{segments[1]}"
        expected_sig = OpenSSL::HMAC.digest('SHA256', secret, signing_input)
        actual_sig = Base64.urlsafe_decode64(segments[2] + '=' * (4 - segments[2].length % 4))

        return nil unless ActiveSupport::SecurityUtils.secure_compare(expected_sig, actual_sig)

        payload_segment = segments[1]
        JSON.parse(Base64.urlsafe_decode64(payload_segment + '=' * (4 - payload_segment.length % 4)))
      rescue StandardError => e
        Rails.logger.debug("[Igaralead::HubTokenValidator] HS256 decode failed: #{e.message}")
        nil
      end

      def fetch_jwks
        @jwks_cache ||= {}
        cached = @jwks_cache[:data]
        cached_at = @jwks_cache[:fetched_at]

        if cached && cached_at && (Time.current - cached_at) < JWKS_CACHE_TTL
          return cached
        end

        jwks_url = ENV.fetch('HUB_JWKS_URL', nil)
        # Fall back to SSO JWKS
        jwks_url ||= "#{ENV.fetch('SSO_URL', 'http://localhost:8003')}/jwks" if ENV['SSO_URL'].present?
        return nil if jwks_url.blank?

        uri = URI(jwks_url)
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = uri.scheme == 'https'
        http.open_timeout = 5
        http.read_timeout = 5

        response = http.request(Net::HTTP::Get.new(uri))
        return nil unless response.is_a?(Net::HTTPSuccess)

        data = JSON.parse(response.body)
        @jwks_cache = { data: data, fetched_at: Time.current }
        data
      rescue StandardError => e
        Rails.logger.warn("[Igaralead::HubTokenValidator] JWKS fetch failed: #{e.message}")
        nil
      end

      def build_rsa_key(key_data)
        n = Base64.urlsafe_decode64(key_data['n'] + '=' * (4 - key_data['n'].length % 4))
        e = Base64.urlsafe_decode64(key_data['e'] + '=' * (4 - key_data['e'].length % 4))

        key = OpenSSL::PKey::RSA.new
        # Ruby 3.0+ uses set_key
        if key.respond_to?(:set_key)
          key.set_key(OpenSSL::BN.new(n, 2), OpenSSL::BN.new(e, 2), nil)
        else
          # Fallback: construct via ASN1
          asn1 = OpenSSL::ASN1::Sequence.new([
                                               OpenSSL::ASN1::Integer.new(OpenSSL::BN.new(n, 2)),
                                               OpenSSL::ASN1::Integer.new(OpenSSL::BN.new(e, 2))
                                             ])
          key = OpenSSL::PKey::RSA.new(asn1.to_der)
        end
        key
      rescue StandardError => e
        Rails.logger.warn("[Igaralead::HubTokenValidator] RSA key build failed: #{e.message}")
        nil
      end
    end
  end
end
