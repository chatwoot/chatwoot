require 'rails_helper'

RSpec.describe 'Signup enforcement', type: :request do
  let(:signup_config_name) { 'ENABLE_ACCOUNT_SIGNUP' }

  before do
    GlobalConfig.clear_cache
    InstallationConfig.where(name: signup_config_name).delete_all
    InstallationConfig.create!(name: signup_config_name, value: false, locked: false)
  end

  after do
    InstallationConfig.where(name: signup_config_name).delete_all
    GlobalConfig.clear_cache
    OmniAuth.config.mock_auth[:google_oauth2] = nil
  end

  describe 'POST /api/v1/accounts' do
    it 'blocks signup when the config is stored as boolean false' do
      post api_v1_accounts_url,
           params: {
             account_name: 'verify',
             user_full_name: 'Verify User',
             email: "verify-#{SecureRandom.hex(4)}@example.com",
             password: 'Password1!'
           },
           as: :json

      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'POST /api/v2/accounts' do
    it 'blocks signup when the config is stored as boolean false' do
      post api_v2_accounts_url,
           params: {
             email: "verify-#{SecureRandom.hex(4)}@example.com",
             password: 'Password1!'
           },
           as: :json

      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'GET /omniauth/google_oauth2/callback' do
    let(:email_validation_service) { instance_double(Account::SignUpEmailValidationService, perform: true) }

    before do
      OmniAuth.config.test_mode = true
      allow(Account::SignUpEmailValidationService).to receive(:new).and_return(email_validation_service)
    end

    it 'redirects to no-account-found when the config is stored as boolean false' do
      OmniAuth.config.mock_auth[:google_oauth2] = OmniAuth::AuthHash.new(
        provider: 'google',
        uid: '123545',
        info: {
          name: 'test',
          email: "verify-#{SecureRandom.hex(4)}@example.com",
          image: 'https://example.com/image.jpg'
        }
      )

      with_modified_env FRONTEND_URL: 'http://www.example.com' do
        get '/omniauth/google_oauth2/callback'

        expect(response).to redirect_to('http://www.example.com/auth/google_oauth2/callback')
        follow_redirect!
        expect(response).to redirect_to(%r{/app/login\?error=no-account-found$})
      end
    end
  end
end
