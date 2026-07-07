# frozen_string_literal: true

class Autonomia::Sso::TokenStore
  TOKEN_PURPOSE = :autonomia_identity_authorization_token
  REFRESH_TOKEN_PURPOSE = :autonomia_identity_refresh_token
  DEFAULT_TTL = 55.minutes

  def self.write!(user_link, token)
    new(user_link).write!(token)
  end

  def self.authorization_token_for(user)
    Autonomia::UserLink
      .where(user: user)
      .where("metadata ? 'identity_authorization_token'")
      .order(updated_at: :desc, id: :desc)
      .each do |user_link|
        token = new(user_link).authorization_token
        return token if token.present?
      end

    nil
  end

  def initialize(user_link)
    @user_link = user_link
  end

  def write!(token)
    return if token.context_token.blank?

    metadata = (@user_link.metadata || {}).merge(
      'identity_authorization_token' => encryptor.encrypt_and_sign(token.context_token, purpose: TOKEN_PURPOSE),
      'identity_authorization_token_expires_at' => expires_at(token).iso8601
    )
    refresh_token = token_refresh_token(token)
    if refresh_token.present?
      metadata['identity_refresh_token'] = encryptor.encrypt_and_sign(refresh_token, purpose: REFRESH_TOKEN_PURPOSE)
    end
    @user_link.update!(metadata: metadata)
  end

  def authorization_token
    return refresh_authorization_token if token_expired?

    encrypted_token = @user_link.metadata&.fetch('identity_authorization_token', nil)
    return if encrypted_token.blank?

    encryptor.decrypt_and_verify(encrypted_token, purpose: TOKEN_PURPOSE)
  rescue ActiveSupport::MessageEncryptor::InvalidMessage, ActiveSupport::MessageVerifier::InvalidSignature
    nil
  end

  private

  def refresh_authorization_token
    refresh_token = stored_refresh_token
    return if refresh_token.blank?

    token = Autonomia::Sso::Client.new.refresh_token!(refresh_token: refresh_token)
    write!(token)
    token.context_token
  rescue StandardError => e
    Rails.logger.warn(
      "[Autonomia SSO] Failed to refresh stored Auth token for user_link=#{@user_link.id}: #{e.class}: #{e.message}"
    )
    nil
  end

  def stored_refresh_token
    encrypted_token = @user_link.metadata&.fetch('identity_refresh_token', nil)
    return if encrypted_token.blank?

    encryptor.decrypt_and_verify(encrypted_token, purpose: REFRESH_TOKEN_PURPOSE)
  rescue ActiveSupport::MessageEncryptor::InvalidMessage, ActiveSupport::MessageVerifier::InvalidSignature
    nil
  end

  def token_expired?
    expires_at = @user_link.metadata&.fetch('identity_authorization_token_expires_at', nil)
    return true if expires_at.blank?

    Time.zone.parse(expires_at).past?
  rescue ArgumentError
    true
  end

  def expires_at(token)
    ttl = token.expires_in.to_i.positive? ? token.expires_in.to_i.seconds : DEFAULT_TTL
    Time.current + ttl
  end

  def token_refresh_token(token)
    return unless token.respond_to?(:refresh_token)

    token.refresh_token
  end

  def encryptor
    key_len = ActiveSupport::MessageEncryptor.key_len
    secret = Rails.application.key_generator.generate_key('autonomia-identity-token-store', key_len)
    ActiveSupport::MessageEncryptor.new(secret, serializer: JSON)
  end
end
