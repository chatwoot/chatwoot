class DeviceVerification::TokenService < BaseTokenService
  pattr_initialize [:user, :jti, :token]

  TOKEN_EXPIRY = 10.minutes
  TOKEN_TYPE = 'device_verification'.freeze

  def self.stamp_for(user)
    Digest::SHA256.hexdigest("#{user.email}:#{user.encrypted_password}")[0, 16]
  end

  def generate_token
    @payload = {
      user_id: user.id,
      jti: jti,
      type: TOKEN_TYPE,
      stamp: self.class.stamp_for(user),
      exp: TOKEN_EXPIRY.from_now.to_i
    }
    super
  end

  def decode_claims
    claims = decode_token
    return {} unless claims[:type] == TOKEN_TYPE
    return {} unless claims[:user_id].present? && claims[:jti].present? && claims[:stamp].present?

    claims
  end
end
