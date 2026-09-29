require 'rails_helper'

RSpec.describe Passkeys::RegistrationService do
  include PasskeySpecHelpers

  let(:user) { create(:user) }
  let(:service) { described_class.new(user: user) }

  describe '#options' do
    it 'asks for a user-verified discoverable credential tied to a random user handle' do
      options = service.options.as_json.deep_stringify_keys

      expect(options['rp']['id']).to eq('app.example.com')
      expect(options['user']['id']).to eq(user.reload.webauthn_id)
      expect(options['user']['id']).to match(/\A[A-Za-z0-9_-]{86}\z/)
      expect(options['authenticatorSelection']).to include('residentKey' => 'required', 'userVerification' => 'required')
      expect(options['attestation']).to eq('none')
    end

    it 'excludes passkeys the user already has' do
      passkey = register_passkey(user)

      expect(service.options.as_json.deep_stringify_keys['excludeCredentials'].pluck('id')).to eq([passkey.external_id])
    end

    it 'keeps the user handle stable across calls' do
      first = service.options.as_json.deep_stringify_keys['user']['id']

      expect(described_class.new(user: user.reload).options.as_json.deep_stringify_keys['user']['id']).to eq(first)
    end
  end

  describe '#register' do
    it 'stores the verified credential' do
      passkey = register_passkey(user, name: 'Work laptop')

      expect(passkey).to be_persisted
      expect(passkey).to have_attributes(user: user, name: 'Work laptop', transports: ['internal'])
      expect(passkey.public_key).to be_present
    end

    it 'rejects a credential created without user verification' do
      options = service.options

      expect(service.register(credential: passkey_client.create(challenge: options.challenge), name: 'x')).to be_nil
      expect(user.passkeys).to be_empty
    end

    it 'rejects a credential created for another origin' do
      options = service.options
      credential = WebAuthn::FakeClient.new('https://evil.example.net').create(challenge: options.challenge, user_verified: true)

      expect(service.register(credential: credential, name: 'x')).to be_nil
    end

    it 'rejects a challenge the server did not issue' do
      service.options
      credential = passkey_client.create(challenge: WebAuthn::Credential.options_for_get.challenge, user_verified: true)

      expect(service.register(credential: credential, name: 'x')).to be_nil
    end

    it 'uses each challenge once' do
      options = service.options
      service.register(credential: passkey_client.create(challenge: options.challenge, user_verified: true), name: 'one')

      second = passkey_client.create(challenge: options.challenge, user_verified: true)
      expect(service.register(credential: second, name: 'two')).to be_nil
      expect(user.passkeys.count).to eq(1)
    end

    it 'rejects a credential already registered to another user' do
      options = service.options
      credential = passkey_client.create(challenge: options.challenge, user_verified: true)
      create(:user).passkeys.create!(external_id: credential['id'], public_key: 'key', name: 'theirs')

      expect(service.register(credential: credential, name: 'x')).to be_nil
      expect(user.passkeys).to be_empty
    end

    it 'treats malformed input as a failed registration' do
      service.options

      expect(service.register(credential: { 'id' => 'x', 'rawId' => 'y', 'response' => {} }, name: 'x')).to be_nil
    end
  end
end
