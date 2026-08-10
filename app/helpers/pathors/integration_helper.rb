module Pathors::IntegrationHelper
  # Proof-of-initiation token for the Pathors OAuth connect flow.
  #
  # Signed with the shared connect secret (PATHORS_CONNECT_STATE_SECRET on both
  # deployments), it tells the Pathors authorization server which Chatwoot
  # account the connect is about — and that an administrator of that account,
  # not someone with a hand-crafted URL, initiated it. It doubles as the OAuth
  # `state` parameter so the callback can recover the account without session
  # storage.
  #
  # Modeled on Linear::IntegrationHelper, with two deliberate differences:
  # a dedicated shared secret (Pathors stores the OAuth client secret hashed,
  # so it cannot verify an HMAC), and an explicit 5-minute exp (the verifier
  # also enforces a max age on iat).
  TOKEN_TTL = 5.minutes

  def generate_pathors_token(account)
    return if pathors_connect_secret.blank?

    JWT.encode(pathors_token_payload(account), pathors_connect_secret, 'HS256')
  rescue StandardError => e
    Rails.logger.error("Failed to generate Pathors connect token: #{e.message}")
    nil
  end

  def pathors_token_payload(account)
    {
      account_id: account.id,
      account_name: account.name,
      iat: Time.current.to_i,
      exp: TOKEN_TTL.from_now.to_i
    }
  end

  # @return [Integer, nil] the account ID or nil if the token is invalid
  def verify_pathors_token(token)
    return if token.blank? || pathors_connect_secret.blank?

    JWT.decode(token, pathors_connect_secret, true, {
                 algorithm: 'HS256',
                 verify_expiration: true
               }).first['account_id']
  rescue StandardError => e
    Rails.logger.error("Unexpected error verifying Pathors connect token: #{e.message}")
    nil
  end

  private

  def pathors_connect_secret
    @pathors_connect_secret ||= GlobalConfigService.load('PATHORS_CONNECT_STATE_SECRET', nil)
  end
end
