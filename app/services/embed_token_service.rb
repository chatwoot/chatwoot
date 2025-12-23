# frozen_string_literal: true

class EmbedTokenService
  JWT_SECRET = ENV.fetch('JWT_SECRET', Rails.application.secret_key_base)
  JWT_ALGORITHM = 'HS256'
  JWT_ISSUER = 'synkicrm'
  JWT_AUDIENCE = 'embed'

  class << self
    def generate(user:, account:, inbox: nil, created_by: nil, note: nil)
      jti = SecureRandom.uuid
      token_digest = Digest::SHA256.hexdigest(jti)

      embed_token = EmbedToken.create!(
        jti: jti,
        token_digest: token_digest,
        user: user,
        account: account,
        inbox: inbox,
        created_by: created_by,
        note: note
      )

      jwt_token = encode_jwt(
        user_id: user.id,
        account_id: account.id,
        inbox_id: inbox&.id,
        jti: jti
      )

      {
        embed_token: embed_token,
        token: jwt_token,
        embed_url: build_embed_url(jwt_token)
      }
    end

    def validate_and_authenticate(token)
      decoded = decode_jwt(token)
      return nil unless decoded

      jti = decoded['jti']
      embed_token = EmbedToken.find_by(jti: jti)

      return nil unless embed_token
      return nil if embed_token.revoked?

      # Verify user and account still exist and are valid
      user = User.find_by(id: decoded['sub'])
      account = Account.find_by(id: decoded['account_id'])

      return nil unless user&.active_for_authentication?
      return nil unless account

      # Verify user has access to account
      account_user = AccountUser.find_by(account: account, user: user)
      return nil unless account_user

      # Mark token as used
      embed_token.mark_used!

      {
        user: user,
        account: account,
        inbox: embed_token.inbox,
        embed_token: embed_token
      }
    end

    def revoke(embed_token)
      embed_token.revoke!
    end

    private

    def encode_jwt(user_id:, account_id:, inbox_id: nil, jti:)
      payload = {
        sub: user_id,
        account_id: account_id,
        jti: jti,
        aud: JWT_AUDIENCE,
        iss: JWT_ISSUER,
        iat: Time.now.to_i
      }
      payload[:inbox_id] = inbox_id if inbox_id

      JWT.encode(payload, JWT_SECRET, JWT_ALGORITHM)
    end

    def decode_jwt(token)
      decoded = JWT.decode(
        token,
        JWT_SECRET,
        true,
        {
          algorithm: JWT_ALGORITHM,
          verify_aud: true,
          verify_iss: true,
          aud: JWT_AUDIENCE,
          iss: JWT_ISSUER
        }
      )
      decoded[0]
    rescue JWT::DecodeError, JWT::VerificationError, JWT::ExpiredSignature
      nil
    end

    def build_embed_url(token)
      base_url = ENV.fetch('FRONTEND_URL', 'https://chat.synkicrm.com.br')
      "#{base_url}/embed/auth?token=#{token}"
    end
  end
end

