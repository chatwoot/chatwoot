class Mfa::TokenService < BaseTokenService
  pattr_initialize [:user, :token]

  MFA_TOKEN_EXPIRY = 5.minutes
  TOKEN_TYPE = 'mfa_login'.freeze

  def generate_token
    @payload = build_payload
    super
  end

  def verify_token
    decoded = decode_token
    return nil if decoded.blank?
    # Positive purpose check: rejects untyped legacy tokens and tokens minted
    # for other purposes (mfa_setup, device verification).
    return nil unless decoded[:token_type] == TOKEN_TYPE

    User.find(decoded[:user_id])
  rescue ActiveRecord::RecordNotFound
    nil
  end

  private

  def build_payload
    {
      user_id: user.id,
      token_type: TOKEN_TYPE,
      exp: MFA_TOKEN_EXPIRY.from_now.to_i
    }
  end
end
