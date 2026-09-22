require 'rails_helper'

RSpec.describe 'Device verification on sign-in', type: :request do
  let!(:account) { create(:account) }
  let!(:user) { create(:user, password: 'Password1!', account: account) }
  let(:emailed_codes) { [] }
  let(:mailer_message) { instance_double(ActionMailer::MessageDelivery, deliver_later: true) }

  def sign_in_params
    { email: user.email, password: 'Password1!' }
  end

  def sign_in!(extra = {})
    post new_user_session_url, params: sign_in_params.merge(extra), as: :json
  end

  def issued_token
    response.parsed_body['mfa_token']
  end

  def redeem!(token, code, extra = {})
    post new_user_session_url, params: { mfa_token: token, otp_code: code }.merge(extra), as: :json
  end

  shared_context 'with device verification enabled' do
    before do
      allow(ChatwootApp).to receive(:chatwoot_cloud?).and_return(true)
      GlobalConfig.clear_cache
      create(:installation_config, name: 'DEVICE_VERIFICATION_ENABLED', value: true)
      allow(Enterprise::DeviceVerificationMailer).to receive(:verification_code) do |_user, encrypted_code, _meta|
        emailed_codes << DeviceVerification.decrypt_code(encrypted_code)
        mailer_message
      end
      allow(Enterprise::DeviceVerificationMailer).to receive(:new_device).and_return(mailer_message)
    end
  end

  describe 'challenge issuance' do
    include_context 'with device verification enabled'

    it 'returns a 206 challenge with no auth tokens for an unrecognized device' do
      sign_in!

      expect(response).to have_http_status(:partial_content)
      body = response.parsed_body
      expect(body['mfa_required']).to be(true)
      expect(body['verification_channel']).to eq('email')
      expect(body['mfa_token']).to be_present
      expect(response.headers['access-token']).to be_nil
      expect(emailed_codes.size).to eq(1)
    end

    it 'does not run session revocation for an unverified password-holder' do
      user.create_token
      user.save!
      tokens_before = user.reload.tokens
      expect(tokens_before).not_to be_empty

      sign_in!(revoke_all_sessions: true)

      expect(response).to have_http_status(:partial_content)
      expect(user.reload.tokens).to eq(tokens_before)
    end

    it 'challenges credentials supplied via headers, not only body params' do
      post new_user_session_url,
           params: {},
           headers: { 'email' => user.email, 'password' => 'Password1!' },
           as: :json

      expect(response).to have_http_status(:partial_content)
      expect(response.parsed_body['verification_channel']).to eq('email')
      expect(response.headers['access-token']).to be_nil
    end

    it 'fails closed with 429 when the issuance budget is exhausted' do
      allow(DeviceVerification::ChallengeService).to receive(:new)
        .and_return(instance_double(DeviceVerification::ChallengeService, issue!: nil))

      sign_in!

      expect(response).to have_http_status(:too_many_requests)
      expect(response.headers['access-token']).to be_nil
    end

    it 'still rejects bad passwords with 401' do
      post new_user_session_url, params: { email: user.email, password: 'wrong' }, as: :json

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe 'redemption' do
    include_context 'with device verification enabled'

    it 'completes sign-in with the correct code, sets the device cookie, notifies' do
      sign_in!
      redeem!(issued_token, emailed_codes.last)

      expect(response).to have_http_status(:success)
      expect(response.headers['access-token']).to be_present
      expect(response.cookies.keys).to include("cw_dv_#{user.id}")
      expect(Enterprise::DeviceVerificationMailer).to have_received(:new_device)
      expect(user.reload.user_sessions.count).to eq(1)
    end

    it 'does not set the trusted-device cookie when remember_device is false' do
      sign_in!
      redeem!(issued_token, emailed_codes.last, remember_device: false)

      expect(response).to have_http_status(:success)
      expect(response.headers['access-token']).to be_present
      expect(response.cookies.keys).not_to include("cw_dv_#{user.id}")
    end

    it 'sets the trusted-device cookie by default when remember_device is absent' do
      sign_in!
      redeem!(issued_token, emailed_codes.last)

      expect(response.cookies.keys).to include("cw_dv_#{user.id}")
    end

    it 'still completes sign-in when the new-device email fails to enqueue' do
      sign_in!
      allow(Enterprise::DeviceVerificationMailer).to receive(:new_device).and_raise(StandardError, 'queue down')

      redeem!(issued_token, emailed_codes.last)

      expect(response).to have_http_status(:success)
      expect(response.headers['access-token']).to be_present
    end

    it 'rejects a wrong code with 400 and no session' do
      sign_in!
      redeem!(issued_token, '000000')

      expect(response).to have_http_status(:bad_request)
      expect(response.headers['access-token']).to be_nil
    end

    it 'locks the challenge after 5 wrong attempts even for the right code' do
      sign_in!
      token = issued_token
      5.times { redeem!(token, '000000') }
      redeem!(token, emailed_codes.last)

      expect(response).to have_http_status(:bad_request)
      expect(response.parsed_body['error']).to be_present
      expect(response.headers['access-token']).to be_nil
    end

    it 'rejects redemption after a password change with 400' do
      sign_in!
      token = issued_token
      code = emailed_codes.last
      user.update!(password: 'NewPassword1!')
      redeem!(token, code)

      expect(response).to have_http_status(:bad_request)
      expect(response.headers['access-token']).to be_nil
    end

    it 'rejects backup_code submissions with guidance to use the code field' do
      sign_in!
      post new_user_session_url, params: { mfa_token: issued_token, backup_code: '12345678' }, as: :json

      expect(response).to have_http_status(:bad_request)
      expect(response.parsed_body['error']).to eq(I18n.t('errors.device_verification.code_field_required'))
      expect(response.headers['access-token']).to be_nil
    end

    it 'honors an outstanding challenge after the kill switch is turned off' do
      sign_in!
      token = issued_token
      InstallationConfig.find_by(name: 'DEVICE_VERIFICATION_ENABLED').update!(value: false)
      GlobalConfig.clear_cache

      redeem!(token, emailed_codes.last)

      expect(response).to have_http_status(:success)
      expect(response.headers['access-token']).to be_present
    end

    it 'never responds 206 to a redemption attempt' do
      sign_in!
      token = issued_token

      redeem!(token, '000000')
      expect(response).not_to have_http_status(:partial_content)

      redeem!(token, emailed_codes.last)
      expect(response).not_to have_http_status(:partial_content)
    end

    context 'when at the session limit' do
      let(:browser_ua) { 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Safari/605.1.15' }

      around { |example| with_modified_env('MAX_USER_SESSIONS' => '1') { example.run } }

      before do
        client_id = user.create_token.client
        user.save!
        user.user_sessions.create!(client_id: client_id, last_activity_at: Time.current)
      end

      it 'evicts the oldest session and completes sign-in' do
        post new_user_session_url, params: sign_in_params, headers: { 'User-Agent' => browser_ua }, as: :json
        token = issued_token
        post new_user_session_url, params: { mfa_token: token, otp_code: emailed_codes.last },
                                   headers: { 'User-Agent' => browser_ua }, as: :json

        expect(response).to have_http_status(:success)
        expect(response.headers['access-token']).to be_present
        expect(user.reload.user_sessions.count).to eq(1)
      end
    end
  end

  describe 'trusted device skip' do
    include_context 'with device verification enabled'

    it 'does not challenge a device that already verified' do
      sign_in!
      redeem!(issued_token, emailed_codes.last)
      expect(response).to have_http_status(:success)

      sign_in!

      expect(response).to have_http_status(:success)
      expect(response.headers['access-token']).to be_present
      expect(emailed_codes.size).to eq(1)
    end

    it 're-challenges when the trust version was bumped' do
      sign_in!
      redeem!(issued_token, emailed_codes.last)
      User.update_counters(user.id, device_trust_version: 1) # rubocop:disable Rails/SkipsModelValidations

      sign_in!

      expect(response).to have_http_status(:partial_content)
      expect(emailed_codes.size).to eq(2)
    end
  end

  describe 'exclusions' do
    include_context 'with device verification enabled'

    it 'sends MFA users through the real MFA flow, not device verification' do
      skip('Skipping since MFA is not configured in this environment') unless Chatwoot.encryption_configured?
      user.enable_two_factor!
      user.update!(otp_required_for_login: true)

      sign_in!

      expect(response).to have_http_status(:partial_content)
      body = response.parsed_body
      expect(body['mfa_required']).to be(true)
      expect(body['verification_channel']).to be_nil
      expect(emailed_codes).to be_empty
    end

    it 'rejects a device token posted into the MFA flow' do
      skip('Skipping since MFA is not configured in this environment') unless Chatwoot.encryption_configured?
      sign_in!
      token = issued_token
      user.enable_two_factor!
      user.update!(otp_required_for_login: true)

      redeem!(token, emailed_codes.last)

      expect(response).not_to have_http_status(:success)
      expect(response.headers['access-token']).to be_nil
    end

    it 'still blocks SAML users from password auth when the email has stray whitespace' do
      create(:account_saml_settings, account: account)
      saml_user = create(:user, email: 'samluser@example.com', provider: 'saml', password: 'Password1!', account: account)

      post new_user_session_url, params: { email: "  #{saml_user.email.upcase}  ", password: 'Password1!' }, as: :json

      expect(response).to have_http_status(:unauthorized)
      expect(emailed_codes).to be_empty
    end

    it 'never challenges SSO token sign-ins' do
      sso_token = user.generate_sso_auth_token

      post new_user_session_url, params: { email: user.email, sso_auth_token: sso_token }, as: :json

      expect(response).to have_http_status(:success)
      expect(response.headers['access-token']).to be_present
      expect(emailed_codes).to be_empty
    end
  end

  describe 'forget trusted devices' do
    include_context 'with device verification enabled'

    it 'bumps the trust version so known devices re-verify' do
      sign_in!
      redeem!(issued_token, emailed_codes.last)
      auth_headers = response.headers.slice('access-token', 'client', 'uid')
      version_before = user.reload.device_trust_version

      delete '/api/v1/profile/trusted_devices', headers: auth_headers, as: :json

      expect(response).to have_http_status(:ok)
      expect(user.reload.device_trust_version).to eq(version_before + 1)

      sign_in!
      expect(response).to have_http_status(:partial_content)
    end

    it 'returns 404 when the feature is disabled' do
      sign_in!
      redeem!(issued_token, emailed_codes.last)
      auth_headers = response.headers.slice('access-token', 'client', 'uid')
      InstallationConfig.find_by(name: 'DEVICE_VERIFICATION_ENABLED').update!(value: false)
      GlobalConfig.clear_cache

      delete '/api/v1/profile/trusted_devices', headers: auth_headers, as: :json

      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'when the feature is off' do
    it 'signs in directly with the kill switch off on cloud' do
      allow(ChatwootApp).to receive(:chatwoot_cloud?).and_return(true)
      GlobalConfig.clear_cache

      sign_in!

      expect(response).to have_http_status(:success)
      expect(response.headers['access-token']).to be_present
    end

    it 'signs in directly when not on cloud even with the config on' do
      allow(ChatwootApp).to receive(:chatwoot_cloud?).and_return(false)
      GlobalConfig.clear_cache
      create(:installation_config, name: 'DEVICE_VERIFICATION_ENABLED', value: true)

      sign_in!

      expect(response).to have_http_status(:success)
      expect(response.headers['access-token']).to be_present
    end
  end
end
