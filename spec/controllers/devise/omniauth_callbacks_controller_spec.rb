require 'rails_helper'

RSpec.describe 'DeviseOverrides::OmniauthCallbacksController', type: :request do
  before do
    OmniAuth.config.test_mode = true
    OmniAuth.config.mock_auth[:google_oauth2] = OmniAuth::AuthHash.new(
      provider: 'google',
      uid: '123545',
      info: {
        name: 'test',
        email: 'test@example.com'
      }
    )
  end

  describe '#omniauth_sucess' do
    it 'redirects properly without user' do
      get '/omniauth/google_oauth2/callback'
      # expect a 302 redirect to auth/google_oauth2/callback
      expect(response).to redirect_to('http://www.example.com/auth/google_oauth2/callback')

      # expect a 302 redirect to app/login with error
      follow_redirect!
      expect(response).to redirect_to('http://localhost:3000/app/login?error=oauth-no-user')

      # expect app/login page to respond with 200 and render
      follow_redirect!
      expect(response).to have_http_status(:ok)
    end

    it 'redirects properly with user' do
      create(:user, email: 'test@example.com')

      get '/omniauth/google_oauth2/callback'
      # expect a 302 redirect to auth/google_oauth2/callback
      expect(response).to redirect_to('http://www.example.com/auth/google_oauth2/callback')

      follow_redirect!
      expect(response).to redirect_to(%r{/app/login\?email=.+&sso_auth_token=.+$})

      # expect app/login page to respond with 200 and render
      follow_redirect!
      expect(response).to have_http_status(:ok)
    end
  end
end
