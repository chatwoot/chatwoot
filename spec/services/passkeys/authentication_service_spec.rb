require 'rails_helper'

RSpec.describe Passkeys::AuthenticationService do
  include PasskeySpecHelpers

  let(:user) { create(:user) }
  let!(:passkey) { register_passkey(user) }

  def authenticate(credential)
    described_class.new(credential: credential.deep_stringify_keys).perform
  end

  describe '.options' do
    it 'asks for user verification without naming any credentials' do
      options = described_class.options.as_json.deep_stringify_keys

      expect(options['userVerification']).to eq('required')
      expect(options['allowCredentials']).to be_blank
      expect(options['rpId']).to eq('app.example.com')
    end
  end

  describe '#perform' do
    it 'returns the user and records the use' do
      expect(authenticate(passkey_assertion(user))).to eq(user)
      expect(passkey.reload.last_used_at).to be_present
    end

    it 'rejects an assertion without user verification' do
      expect(authenticate(passkey_assertion(user, user_verified: false))).to be_nil
    end

    it 'rejects a replayed assertion' do
      assertion = passkey_assertion(user)
      authenticate(assertion)

      expect(authenticate(assertion)).to be_nil
    end

    it 'rejects a challenge the server did not issue' do
      forged = WebAuthn::Credential.options_for_get.challenge

      expect(authenticate(passkey_assertion(user, challenge: forged))).to be_nil
    end

    it 'rejects an expired challenge' do
      challenge = described_class.options.challenge
      Redis::Alfred.delete(described_class.challenge_key(challenge))

      expect(authenticate(passkey_assertion(user, challenge: challenge))).to be_nil
    end

    it 'rejects an assertion made for another origin' do
      evil_client = WebAuthn::FakeClient.new('https://evil.example.net', authenticator: passkey_client.send(:authenticator))

      expect(authenticate(passkey_assertion(user, client: evil_client, rp_id: 'app.example.com'))).to be_nil
    end

    it 'rejects a user handle that does not belong to the credential' do
      other = create(:user)
      other.ensure_webauthn_id!

      expect(authenticate(passkey_assertion(other))).to be_nil
    end

    it 'rejects a credential that was removed' do
      assertion = passkey_assertion(user)
      passkey.destroy!

      expect(authenticate(assertion)).to be_nil
    end

    it 'rejects a sign count that goes backwards' do
      passkey.update!(sign_count: 100)

      expect(authenticate(passkey_assertion(user, sign_count: 5))).to be_nil
    end

    it 'ignores a client-supplied appid extension' do
      expect(authenticate(passkey_assertion(user).merge('clientExtensionResults' => { 'appid' => true }))).to eq(user)
    end

    it 'treats malformed input as a failed assertion' do
      expect(authenticate({ 'id' => 'x', 'response' => { 'clientDataJSON' => 'not-json' } })).to be_nil
    end
  end
end
