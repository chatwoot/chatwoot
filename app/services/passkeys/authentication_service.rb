class Passkeys::AuthenticationService
  pattr_initialize [:credential!]

  def self.options
    request_options = Passkeys.relying_party.options_for_authentication(user_verification: 'required')
    Redis::Alfred.setex(challenge_key(request_options.challenge), '1', Passkeys::CHALLENGE_TTL)
    request_options
  end

  def self.challenge_key(challenge)
    format(Redis::RedisKeys::PASSKEY_AUTHENTICATION_CHALLENGE, digest: Digest::SHA256.hexdigest(challenge))
  end

  # Returns the passkey's user once the assertion verifies, nil otherwise.
  def perform
    webauthn_credential = WebAuthn::Credential.from_get(credential.except('clientExtensionResults'), relying_party: relying_party)
    challenge = Base64.urlsafe_encode64(webauthn_credential.response.client_data.challenge, padding: false)
    return unless Passkeys.consume(self.class.challenge_key(challenge))

    passkey = find_passkey(webauthn_credential)
    return unless passkey

    # Locked so concurrent sign-ins cannot move the stored sign count backwards.
    passkey.with_lock do
      webauthn_credential.verify(challenge, public_key: passkey.public_key, sign_count: passkey.sign_count, user_verification: true)
      passkey.update!(sign_count: webauthn_credential.sign_count, backed_up: webauthn_credential.backed_up?, last_used_at: Time.current)
    end
    passkey.user
  rescue StandardError => e
    # The credential is attacker-controlled; malformed CBOR or JSON surfaces as
    # assorted non-WebAuthn errors and must read as a failed assertion.
    Rails.logger.info("Passkey sign-in rejected: #{e.class}")
    nil
  end

  private

  def find_passkey(webauthn_credential)
    passkey = Passkey.includes(:user).find_by(external_id: webauthn_credential.id)
    passkey if passkey && passkey.user.webauthn_id == webauthn_credential.user_handle
  end

  def relying_party
    @relying_party ||= Passkeys.relying_party
  end
end
