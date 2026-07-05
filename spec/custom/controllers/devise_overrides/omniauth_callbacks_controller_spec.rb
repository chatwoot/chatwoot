require 'rails_helper'

# Verifies the OAuth/SAML half of the SSO-only lockdown
# (custom/app/controllers/custom/devise_overrides/omniauth_callbacks_controller.rb).
# Google OAuth and SAML both mint an sso_auth_token via #omniauth_success — a
# token the SessionsController lock cannot distinguish from a legitimate
# Platform-minted one — so the flag must block them here or it is bypassable.
RSpec.describe 'SSO-only login enforcement (OAuth/SAML)', type: :request do
  let!(:user) { create(:user, email: 'oauth-user@example.com') }

  def set_omniauth_config(email)
    OmniAuth.config.test_mode = true
    OmniAuth.config.mock_auth[:google_oauth2] = OmniAuth::AuthHash.new(
      provider: 'google', uid: '123545',
      info: { name: 'test', email: email, image: 'https://example.com/image.jpg' }
    )
  end

  context 'when ENABLE_SSO_ONLY_LOGIN is off (default)' do
    it 'still lets OAuth mint an sso_auth_token (overlay inert)' do
      with_modified_env FRONTEND_URL: 'http://www.example.com' do
        set_omniauth_config(user.email)
        get '/omniauth/google_oauth2/callback'
        follow_redirect!

        expect(response).to redirect_to(%r{/app/login\?email=.+&sso_auth_token=.+$})
      end
    end
  end

  context 'when ENABLE_SSO_ONLY_LOGIN is on' do
    before do
      allow(GlobalConfigService).to receive(:load).and_call_original
      allow(GlobalConfigService).to receive(:load).with('ENABLE_SSO_ONLY_LOGIN', 'false').and_return('true')
    end

    it 'refuses OAuth login and mints no sso_auth_token' do
      with_modified_env FRONTEND_URL: 'http://www.example.com' do
        set_omniauth_config(user.email)
        get '/omniauth/google_oauth2/callback'
        follow_redirect!

        expect(response).to redirect_to(%r{/app/login\?error=sso-only-login$})
        expect(response.location).not_to include('sso_auth_token')
      end
    end
  end
end
