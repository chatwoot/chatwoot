require 'webauthn/fake_client'

module PasskeySpecHelpers
  PASSKEY_ORIGIN = 'https://app.example.com'.freeze

  def self.included(base)
    base.around { |example| with_modified_env(FRONTEND_URL: PASSKEY_ORIGIN) { example.run } }
    base.before do
      create(:installation_config, name: 'PASSKEYS_ENABLED', value: true)
      GlobalConfig.clear_cache
    end
  end

  def passkey_client
    @passkey_client ||= WebAuthn::FakeClient.new(PASSKEY_ORIGIN)
  end

  def register_passkey(user, client: passkey_client, name: 'Laptop')
    service = Passkeys::RegistrationService.new(user: user)
    options = service.options
    service.register(credential: client.create(challenge: options.challenge, user_verified: true), name: name)
  end

  def passkey_assertion(user, client: passkey_client, challenge: Passkeys::AuthenticationService.options.challenge, **overrides)
    client.get(challenge: challenge, user_verified: true, user_handle: Base64.urlsafe_decode64(user.webauthn_id), **overrides)
  end
end
