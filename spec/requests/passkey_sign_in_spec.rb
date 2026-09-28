require 'rails_helper'

RSpec.describe 'Passkey sign-in', type: :request do
  include PasskeySpecHelpers

  let(:account) { create(:account) }
  let(:user) { create(:user, account: account, password: 'Test@123456') }

  before { register_passkey(user) }

  def sign_in_with_passkey(credential = nil)
    post '/passkey_sign_in_options', as: :json
    challenge = response.parsed_body['challenge']
    credential ||= passkey_assertion(user, challenge: challenge)
    post '/auth/sign_in', params: { passkey_credential: credential }, as: :json
  end

  it 'issues request options without naming any user or credential' do
    post '/passkey_sign_in_options', as: :json

    expect(response).to have_http_status(:success)
    expect(response.parsed_body['challenge']).to be_present
    expect(response.parsed_body['allowCredentials']).to be_blank
  end

  it 'signs the user in and tracks the session' do
    sign_in_with_passkey

    expect(response).to have_http_status(:success)
    expect(response.parsed_body['data']['email']).to eq(user.email)
    expect(response.headers['access-token']).to be_present
    expect(user.user_sessions.count).to eq(1)
  end

  it 'rejects a replayed assertion' do
    sign_in_with_passkey
    replay = request.params['passkey_credential']
    post '/auth/sign_in', params: { passkey_credential: replay }, as: :json

    expect(response).to have_http_status(:unauthorized)
    expect(response.parsed_body['error_code']).to eq('passkey_invalid')
  end

  it 'rejects an assertion without user verification' do
    post '/passkey_sign_in_options', as: :json
    sign_in_with_passkey(passkey_assertion(user, challenge: response.parsed_body['challenge'], user_verified: false))

    expect(response).to have_http_status(:unauthorized)
  end

  it 'does not fall through to password sign-in when a passkey credential is present' do
    post '/auth/sign_in', params: { passkey_credential: { id: 'x' }, email: user.email, password: 'Test@123456' }, as: :json

    expect(response).to have_http_status(:unauthorized)
    expect(response.headers['access-token']).to be_nil
  end

  it 'rejects users who cannot sign in' do
    user.update!(confirmed_at: nil)
    sign_in_with_passkey

    expect(response).to have_http_status(:unauthorized)
  end

  it 'rejects users who moved to SAML after registering a passkey' do
    user.update!(provider: 'saml')
    sign_in_with_passkey

    expect(response).to have_http_status(:unauthorized)
  end

  it 'rejects passkey sign-in when the feature is disabled' do
    post '/passkey_sign_in_options', as: :json
    challenge = response.parsed_body['challenge']
    InstallationConfig.find_by(name: 'PASSKEYS_ENABLED').update!(value: false)
    GlobalConfig.clear_cache

    post '/auth/sign_in', params: { passkey_credential: passkey_assertion(user, challenge: challenge) }, as: :json

    expect(response).to have_http_status(:unauthorized)
    post '/passkey_sign_in_options', as: :json
    expect(response).to have_http_status(:not_found)
  end

  context 'with MFA' do
    before do
      skip('Skipping since MFA is not configured in this environment') unless Chatwoot.encryption_configured?
    end

    it 'does not ask an MFA user for a one-time code' do
      user.enable_two_factor!
      user.update!(otp_required_for_login: true)
      sign_in_with_passkey

      expect(response).to have_http_status(:success)
      expect(response.parsed_body['mfa_required']).to be_nil
      expect(response.headers['access-token']).to be_present
    end

    it 'lets a user pending enforced MFA sign in with a passkey but still gates password sign-in' do
      account.update!(settings: account.settings.merge('enforce_mfa' => true))
      expect(user.reload.mfa_enforcement_pending?).to be(true)

      sign_in_with_passkey
      expect(response).to have_http_status(:success)

      post '/auth/sign_in', params: { email: user.email, password: 'Test@123456' }, as: :json
      expect(response).to have_http_status(:partial_content)
      expect(response.parsed_body['mfa_setup_required']).to be(true)
    end
  end
end
