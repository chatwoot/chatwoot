require 'rails_helper'

RSpec.describe 'Session authentication responses', type: :request do
  let(:account) { create(:account) }
  let(:user) { create(:user, account: account, password: 'Test@123456') }
  let(:response_data) { response.parsed_body.fetch('data') }

  before { account.enable_features!(:api_and_webhooks) }

  after { Current.reset }

  it 'returns self credentials after password sign-in' do
    post '/auth/sign_in', params: { email: user.email, password: 'Test@123456' }, as: :json

    expect(response).to have_http_status(:success)
    expect(response_data).to include('access_token' => user.access_token.token, 'pubsub_token' => user.pubsub_token)
    expect(Current.user).to be_nil
  end

  it 'returns self credentials after SSO sign-in' do
    post '/auth/sign_in', params: { email: user.email, sso_auth_token: user.generate_sso_auth_token }, as: :json

    expect(response).to have_http_status(:success)
    expect(response_data).to include('access_token' => user.access_token.token, 'pubsub_token' => user.pubsub_token)
    expect(Current.user).to be_nil
  end

  it 'does not return self credentials for an invalid password' do
    post '/auth/sign_in', params: { email: user.email, password: 'invalid' }, as: :json

    expect(response).to have_http_status(:unauthorized)
    expect(response.parsed_body).not_to have_key('data')
    expect(Current.user).to be_nil
  end

  context 'with MFA' do
    before do
      skip('Skipping since MFA is not configured in this environment') unless Chatwoot.encryption_configured?
      user.enable_two_factor!
    end

    it 'returns self credentials after OTP verification' do
      user.update!(otp_required_for_login: true)
      token = Mfa::TokenService.new(user: user).generate_token

      post '/auth/sign_in', params: { mfa_token: token, otp_code: user.current_otp }, as: :json

      expect(response).to have_http_status(:success)
      expect(response_data).to include('access_token' => user.access_token.token, 'pubsub_token' => user.pubsub_token)
      expect(Current.user).to be_nil
    end

    it 'returns self credentials after backup code verification' do
      user.update!(otp_required_for_login: true)
      backup_codes = user.generate_backup_codes!
      token = Mfa::TokenService.new(user: user).generate_token

      post '/auth/sign_in', params: { mfa_token: token, backup_code: backup_codes.first }, as: :json

      expect(response).to have_http_status(:success)
      expect(response_data).to include('access_token' => user.access_token.token, 'pubsub_token' => user.pubsub_token)
      expect(Current.user).to be_nil
    end

    it 'returns self credentials and backup codes after MFA enrollment' do
      account.update!(enforce_mfa: true)
      token = Mfa::SetupTokenService.new(user: user).generate_token

      post '/auth/sign_in', params: { mfa_setup_token: token, otp_code: user.current_otp }, as: :json

      expect(response).to have_http_status(:success)
      expect(response_data).to include('access_token' => user.access_token.token, 'pubsub_token' => user.pubsub_token)
      expect(response.parsed_body['backup_codes'].size).to eq(10)
      expect(Current.user).to be_nil
    end
  end
end
