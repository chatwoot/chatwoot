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

  describe 'SAML SLO (Single Logout)' do
    let(:saml_user) { create(:user, email: 'saml_user@example.com', provider: 'saml', account: account) }

    before do
      # Create some active sessions for the user
      saml_user.tokens = {
        'client1' => { 'token' => 'token1', 'expiry' => 1.hour.from_now.to_i },
        'client2' => { 'token' => 'token2', 'expiry' => 2.hours.from_now.to_i }
      }
      saml_user.save!
    end

    describe 'SAML_SLO_SESSION_DESTROY_PROC' do
      it 'destroys all user sessions when receiving IdP-initiated logout request' do
        # Create a mock logout request with the user's email as name_id
        logout_request = object_double(logout_request, name_id: saml_user.email)

        # Create a mock OmniAuth strategy
        strategy = object_double(strategy, response_object: logout_request)

        # Create the environment hash that would be passed to the proc
        env = { 'omniauth.strategy' => strategy }

        # Execute the SLO session destroy proc
        SAML_SLO_SESSION_DESTROY_PROC.call(env, {})

        # Verify all sessions were destroyed
        saml_user.reload
        expect(saml_user.tokens).to eq({})
      end

      it 'only destroys sessions for SAML provider users' do
        # Create a non-SAML user
        email_user = create(:user, email: 'email_user@example.com', provider: 'email', account: account)
        email_user.tokens = { 'client1' => { 'token' => 'token1', 'expiry' => 1.hour.from_now.to_i } }
        email_user.save!

        # Create another SAML user
        saml_user2 = create(:user, email: 'another_saml@example.com', provider: 'saml', account: account)
        saml_user2.tokens = { 'client2' => { 'token' => 'token2', 'expiry' => 1.hour.from_now.to_i } }
        saml_user2.save!

        # Create logout request for the second SAML user
        logout_request = object_double(logout_request, name_id: 'another_saml@example.com')

        strategy = object_double(strategy, response_object: logout_request)

        env = { 'omniauth.strategy' => strategy }

        # Execute the SLO session destroy proc
        SAML_SLO_SESSION_DESTROY_PROC.call(env, {})

        # Verify only the targeted SAML user sessions were destroyed
        email_user.reload
        saml_user.reload
        saml_user2.reload

        expect(email_user.tokens).not_to be_empty  # Non-SAML user unaffected
        expect(saml_user.tokens).not_to be_empty   # Different SAML user unaffected
        expect(saml_user2.tokens).to eq({})        # Target SAML user logged out
      end
    end
  end
end
