module X
  module OAuthHelper
    REQUIRED_SCOPES = %w[dm.read dm.write tweet.read tweet.write users.read media.write offline.access].freeze

    def auth_client
      ::OAuth2::Client.new(
        GlobalConfigService.load('X_CLIENT_ID', ''),
        client_secret,
        site: 'https://api.x.com',
        authorize_url: 'https://x.com/i/oauth2/authorize',
        token_url: '/2/oauth2/token'
      )
    end

    def generate_pkce_verifier
      SecureRandom.urlsafe_base64(96)[0...128]
    end

    def generate_pkce_challenge(verifier)
      Base64.urlsafe_encode64(Digest::SHA256.digest(verifier), padding: false)
    end

    def jwt_encode(payload)
      return if client_secret.blank?

      JWT.encode(payload, client_secret, 'HS256')
    rescue StandardError => e
      Rails.logger.error("Failed to generate X token: #{e.message}")
      nil
    end

    def jwt_decode(token)
      return if token.blank? || client_secret.blank?

      JWT.decode(token, client_secret, true, {
                   algorithm: 'HS256',
                   verify_expiration: true
                 }).first
    rescue StandardError => e
      Rails.logger.error("Unexpected error verifying X token: #{e.message}")
      nil
    end

    private

    def client_secret
      @client_secret ||= GlobalConfigService.load('X_CLIENT_SECRET', nil)
    end
  end
end
