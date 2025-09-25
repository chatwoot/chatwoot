class AppleMessagesForBusiness::JwtService
  class << self
    def generate_token(msp_id, secret)
      payload = {
        iss: msp_id,
        aud: msp_id,
        iat: Time.current.to_i
      }
      
      JWT.encode(
        payload,
        Base64.decode64(secret),
        'HS256',
        { alg: 'HS256' }
      )
    end

    def verify_token(token, msp_id, secret)
      JWT.decode(
        token,
        Base64.decode64(secret),
        true,
        { 
          algorithm: 'HS256',
          aud: msp_id,
          verify_aud: true
        }
      )
    rescue JWT::DecodeError => e
      Rails.logger.error "JWT verification failed: #{e.message}"
      raise
    end
  end
end