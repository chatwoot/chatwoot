module ShopifySessionVerification
  extend ActiveSupport::Concern

  # Verifies a session token from App Bridge
  # @param token [String] JWT session token from Shopify App Bridge
  # @return [Boolean] Whether the token is valid
  def verify_shopify_session_token(token)
    return false if token.blank? || client_secret.blank?

    begin
      # Decode the JWT token without verification first to get the payload
      decoded_token, _headers = JWT.decode(token, nil, false)
      
      # Verify token properties
      exp = decoded_token['exp']
      nbf = decoded_token['nbf']
      iss = decoded_token['iss']
      dest = decoded_token['dest']
      aud = decoded_token['aud']
      
      # Validate expiry
      return false if Time.at(exp).utc < Time.now.utc
      
      # Validate not before time
      return false if Time.at(nbf).utc > Time.now.utc
      
      # Validate audience matches our client ID
      return false if aud != client_id
      
      # Validate top-level domains match
      iss_domain = iss.split('://').last.split('/').first
      dest_domain = dest.split('://').last.split('/').first
      return false unless iss_domain.end_with?(dest_domain.split('.').last(2).join('.'))
      
      # Verify signature
      JWT.decode(token, client_secret, true, { algorithm: 'HS256' })
      
      true
    rescue JWT::DecodeError => e
      Rails.logger.error("[Shopify Auth] JWT decode error: #{e.message}")
      false
    rescue StandardError => e
      Rails.logger.error("[Shopify Auth] Session token verification error: #{e.message}")
      false
    end
  end

  private

  def client_id
    @client_id ||= GlobalConfigService.load('SHOPIFY_CLIENT_ID', nil)
  end

  def client_secret
    @client_secret ||= GlobalConfigService.load('SHOPIFY_CLIENT_SECRET', nil)
  end
end 