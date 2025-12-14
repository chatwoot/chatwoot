require 'rails_helper'

RSpec.describe 'Enterprise SAML OmniAuth Callbacks', type: :request do
  let!(:account) { create(:account) }
  let(:saml_settings) { create(:account_saml_settings, account: account) }

  def set_saml_config(email = 'test@example.com')
    OmniAuth.config.test_mode = true
    OmniAuth.config.mock_auth[:saml] = OmniAuth::AuthHash.new(
      provider: 'saml',
      uid: '123545',
      info: {
        name: 'Test User',
        email: email
      }
    )
  end

  before do
    allow(ChatwootApp).to receive(:enterprise?).and_return(true)
    account.enable_features!('saml')
    saml_settings
  end

  describe '#saml callback' do
    it 'creates new user and logs them in' do
      with_modified_env FRONTEND_URL: 'http://www.example.com' do
        set_saml_config('new_user@example.com')

        get "/omniauth/saml/callback?account_id=#{account.id}"

        # expect a 302 redirect to auth/saml/callback
        expect(response).to redirect_to('http://www.example.com/auth/saml/callback')
        follow_redirect!

        # expect redirect to login with SSO token
        expect(response).to redirect_to(%r{/app/login\?email=.+&sso_auth_token=.+$})

        # verify user was created
        user = User.from_email('new_user@example.com')
        expect(user).to be_present
        expect(user.provider).to eq('saml')
      end
    end

    it 'logs in existing user' do
      with_modified_env FRONTEND_URL: 'http://www.example.com' do
        create(:user, email: 'existing@example.com', account: account)
        set_saml_config('existing@example.com')

        get "/omniauth/saml/callback?account_id=#{account.id}"

        # expect a 302 redirect to auth/saml/callback
        expect(response).to redirect_to('http://www.example.com/auth/saml/callback')
        follow_redirect!

        expect(response).to redirect_to(%r{/app/login\?email=.+&sso_auth_token=.+$})
      end
    end
  end
end
