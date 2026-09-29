class Passkeys::RegistrationService
  pattr_initialize [:user!]

  def options
    creation_options = relying_party.options_for_registration(
      user: { id: user.ensure_webauthn_id!, name: user.email, display_name: user.name },
      exclude: user.passkeys.pluck(:external_id),
      authenticator_selection: { resident_key: 'required', require_resident_key: true, user_verification: 'required' },
      attestation: 'none'
    )
    Redis::Alfred.setex(challenge_key, creation_options.challenge, Passkeys::CHALLENGE_TTL)
    creation_options
  end

  def register(credential:, name:)
    challenge = Passkeys.consume(challenge_key)
    return if challenge.blank?

    webauthn_credential = relying_party.verify_registration(credential, challenge, user_verification: true)
    user.passkeys.create!(
      external_id: webauthn_credential.id,
      public_key: webauthn_credential.public_key,
      sign_count: webauthn_credential.sign_count,
      transports: Array(webauthn_credential.response.transports),
      backed_up: webauthn_credential.backed_up?,
      name: name
    )
  rescue StandardError => e
    # Same as sign-in: malformed client input raises assorted non-WebAuthn errors.
    Rails.logger.info("Passkey registration rejected for user #{user.id}: #{e.class}")
    nil
  end

  private

  def challenge_key
    format(Redis::RedisKeys::PASSKEY_REGISTRATION_CHALLENGE, user_id: user.id)
  end

  def relying_party
    @relying_party ||= Passkeys.relying_party
  end
end
