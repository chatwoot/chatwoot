class Mfa::TokenService < BaseTokenService
  pattr_initialize [:user, :token]

  MFA_TOKEN_EXPIRY = 5.minutes

  def generate_token
    @payload = build_payload
    super
  end

  def verify_token
    decoded = decode_token
    return nil if decoded.blank?
    # Purpose-bound tokens (e.g. device verification) are not MFA tokens
    return nil if decoded[:type].present?

    User.find(decoded[:user_id])
  rescue ActiveRecord::RecordNotFound
    nil
  end

  private

  def build_payload
    {
      user_id: user.id,
      exp: MFA_TOKEN_EXPIRY.from_now.to_i
    }
  end
end
