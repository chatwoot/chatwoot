require 'rails_helper'

RSpec.describe 'Profile passkeys API', type: :request do
  include PasskeySpecHelpers

  let(:account) { create(:account) }
  let(:user) { create(:user, account: account, password: 'Test@123456') }
  let(:auth_headers) { user.create_new_auth_token }

  def request_registration_options(password: 'Test@123456', headers: auth_headers)
    post '/api/v1/profile/passkeys/registration_options', params: { password: password }, headers: headers, as: :json
  end

  describe 'POST /api/v1/profile/passkeys/registration_options' do
    it 'returns creation options when the password is correct' do
      request_registration_options

      expect(response).to have_http_status(:success)
      expect(response.parsed_body['challenge']).to be_present
      expect(response.parsed_body['user']['id']).to eq(user.reload.webauthn_id)
    end

    it 'rejects a wrong password' do
      request_registration_options(password: 'wrong')

      expect(response).to have_http_status(:unprocessable_entity)
    end

    context 'when the user has MFA enabled' do
      before do
        skip('Skipping since MFA is not configured in this environment') unless Chatwoot.encryption_configured?
        user.enable_two_factor!
        user.update!(otp_required_for_login: true)
      end

      it 'requires a one-time code as well as the password' do
        request_registration_options

        expect(response).to have_http_status(:unprocessable_entity)
        expect(Redis::Alfred.get(format(Redis::RedisKeys::PASSKEY_REGISTRATION_CHALLENGE, user_id: user.id))).to be_nil
      end

      it 'returns options with a valid one-time code' do
        post '/api/v1/profile/passkeys/registration_options',
             params: { password: 'Test@123456', otp_code: user.reload.current_otp }, headers: auth_headers, as: :json

        expect(response).to have_http_status(:success)
      end
    end

    it 'rejects api access tokens' do
      request_registration_options(headers: { api_access_token: user.access_token.token })

      expect(response).to have_http_status(:forbidden)
    end

    it 'rejects SAML users' do
      user.update!(provider: 'saml')
      request_registration_options

      expect(response).to have_http_status(:forbidden)
    end

    it 'stops at the passkey limit' do
      Passkey::MAX_PER_USER.times { |i| user.passkeys.create!(external_id: "id-#{i}", public_key: 'key', name: "key #{i}") }
      request_registration_options

      expect(response).to have_http_status(:unprocessable_entity)
    end

    it 'returns not found when passkeys are disabled' do
      InstallationConfig.find_by(name: 'PASSKEYS_ENABLED').update!(value: false)
      GlobalConfig.clear_cache
      request_registration_options

      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'POST /api/v1/profile/passkeys' do
    it 'registers a passkey for the challenge issued after the password check' do
      request_registration_options
      credential = passkey_client.create(challenge: response.parsed_body['challenge'], user_verified: true)

      post '/api/v1/profile/passkeys', params: { credential: credential, name: 'MacBook' }, headers: auth_headers, as: :json

      expect(response).to have_http_status(:success)
      expect(response.parsed_body['name']).to eq('MacBook')
      expect(user.passkeys.count).to eq(1)
    end

    it 'rejects a credential without a server-issued challenge' do
      credential = passkey_client.create(challenge: WebAuthn::Credential.options_for_get.challenge, user_verified: true)

      post '/api/v1/profile/passkeys', params: { credential: credential, name: 'MacBook' }, headers: auth_headers, as: :json

      expect(response).to have_http_status(:unprocessable_entity)
      expect(user.passkeys).to be_empty
    end
  end

  describe 'GET /api/v1/profile/passkeys' do
    it 'lists only the current user passkeys without key material' do
      register_passkey(user, name: 'Phone')
      register_passkey(create(:user), client: WebAuthn::FakeClient.new(PasskeySpecHelpers::PASSKEY_ORIGIN))

      get '/api/v1/profile/passkeys', headers: auth_headers, as: :json

      expect(response).to have_http_status(:success)
      payload = response.parsed_body['payload']
      expect(payload.pluck('name')).to eq(['Phone'])
      expect(payload.first.keys).not_to include('public_key', 'external_id')
    end
  end

  describe 'DELETE /api/v1/profile/passkeys/:id' do
    it 'removes the passkey' do
      passkey = register_passkey(user)

      delete "/api/v1/profile/passkeys/#{passkey.id}", headers: auth_headers, as: :json

      expect(response).to have_http_status(:success)
      expect(user.passkeys.reload).to be_empty
    end

    it "cannot remove another user's passkey" do
      passkey = register_passkey(create(:user))

      delete "/api/v1/profile/passkeys/#{passkey.id}", headers: auth_headers, as: :json

      expect(response).to have_http_status(:not_found)
      expect(Passkey.exists?(passkey.id)).to be(true)
    end
  end
end
