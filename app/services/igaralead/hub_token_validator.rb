module Igaralead
  class HubTokenValidator
    JWKS_CACHE_TTL = 1.hour

    class << self
      def validate(token)
        new(token).validate
      end
    end

    def initialize(token)
      @token = token
    end

    def validate
      return nil unless HubClient.jwks_url.present?

      header = JWT.decode(@token, nil, false).last
      kid = header['kid']
      key = find_signing_key(kid)
      return nil unless key

      payload, = JWT.decode(
        @token,
        key,
        true,
        algorithm: 'RS256',
        iss: ENV.fetch('HUB_ISSUER', 'igarahub'),
        aud: ENV.fetch('HUB_AUDIENCE', 'igaralead'),
        verify_iss: true,
        verify_aud: true
      )
      payload
    rescue JWT::DecodeError, JWT::ExpiredSignature, JWT::InvalidIssuerError, JWT::InvalidAudError => e
      Rails.logger.warn("[Igaralead::HubTokenValidator] Token validation failed: #{e.message}")
      nil
    end

    private

    def find_signing_key(kid)
      jwks = cached_jwks
      key_data = jwks.find { |k| k['kid'] == kid }
      return nil unless key_data

      JWT::JWK.new(key_data).public_key
    end

    def cached_jwks
      Rails.cache.fetch('igaralead:hub_jwks', expires_in: JWKS_CACHE_TTL) do
        fetch_jwks
      end
    end

    def fetch_jwks
      response = Faraday.get(HubClient.jwks_url)
      return [] unless response.success?

      JSON.parse(response.body).fetch('keys', [])
    rescue StandardError => e
      Rails.logger.error("[Igaralead::HubTokenValidator] JWKS fetch failed: #{e.message}")
      []
    end
  end
end
