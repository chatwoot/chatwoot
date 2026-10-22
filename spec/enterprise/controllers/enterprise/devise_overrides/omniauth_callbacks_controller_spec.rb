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
    allow(GlobalConfigService).to receive(:load).and_call_original
    allow(GlobalConfigService).to receive(:load).with('FRONTEND_URL', 'http://localhost:3000').and_return('http://www.example.com')
    account.enable_features!('saml')
    saml_settings
  end

  describe '#saml callback' do
    it 'creates new user and logs them in' do
      with_modified_env FRONTEND_URL: 'http://www.example.com' do
        set_saml_config('new_user@example.com')

        get "/omniauth/saml/callback?account_id=#{account.id}"

        expect(response).to redirect_to(%r{/app/login\?email=.+&sso_auth_token=.+$})

        # verify user was created
        user = User.from_email('new_user@example.com')
        expect(user).to be_present
        expect(user.provider).to eq('saml')
      end
    end

    it 'reads the rotated certificate from the IdP metadata URL' do
      with_modified_env FRONTEND_URL: 'http://www.example.com' do
        metadata_url = 'https://idp.example.com/saml/v2/metadata'
        rotated_certificate = build(:account_saml_settings).certificate
        metadata = { sso_url: saml_settings.sso_url, idp_entity_id: saml_settings.idp_entity_id, signing_certificates: [saml_settings.certificate] }
        metadata_service = instance_double(Saml::IdpMetadataService, perform: metadata)
        allow(Saml::IdpMetadataService).to receive(:new).with(metadata_url).and_return(metadata_service)
        saml_settings.update!(metadata_url: metadata_url)
        allow(metadata_service).to receive(:perform).and_return(metadata.merge(signing_certificates: [rotated_certificate]))
        set_saml_config('new_user@example.com')

        travel_to(OpenSSL::X509::Certificate.new(saml_settings.certificate).not_after - 10.minutes) do
          get "/omniauth/saml/callback?account_id=#{account.id}"
        end

        expect(response).to redirect_to(%r{/app/login\?email=.+&sso_auth_token=.+$})
        expect(saml_settings.reload.certificate).to eq(rotated_certificate)
      end
    end

    it 'logs in existing user' do
      with_modified_env FRONTEND_URL: 'http://www.example.com' do
        create(:user, email: 'existing@example.com', account: account)
        set_saml_config('existing@example.com')

        get "/omniauth/saml/callback?account_id=#{account.id}"

        expect(response).to redirect_to(%r{/app/login\?email=.+&sso_auth_token=.+$})
      end
    end

    it 'returns a pending Shopify install redirect to the login flow' do
      with_modified_env FRONTEND_URL: 'http://www.example.com' do
        create(:user, email: 'billing@example.com', account: account)
        set_saml_config('billing@example.com')
        redirect_url = "settings/integrations/shopify?shopify_pending_install=#{'a' * 32}"

        get '/omniauth/saml/callback', params: { account_id: account.id, RelayState: redirect_url }

        query = URI.decode_www_form(URI.parse(response.location).query).to_h
        expect(query['redirect_url']).to eq(redirect_url)
        expect(query).to include('email', 'sso_auth_token')
      end
    end

    it 'redirects mobile SAML login to the mobile deep link' do
      with_modified_env FRONTEND_URL: 'http://www.example.com' do
        create(:user, email: 'mobile@example.com', account: account)
        set_saml_config('mobile@example.com')

        get "/omniauth/saml/callback?account_id=#{account.id}&RelayState=mobile"

        expect(response).to redirect_to(%r{\Achatwootapp://auth/saml\?email=.+&sso_auth_token=.+\z})
      end
    end

    it 'rejects an existing user from another account' do
      with_modified_env FRONTEND_URL: 'http://www.example.com' do
        other_account = create(:account)
        existing_user = create(:user, email: 'existing@example.com', account: other_account, provider: 'email')
        set_saml_config('existing@example.com')

        get "/omniauth/saml/callback?account_id=#{account.id}"

        expect(response).to redirect_to("http://www.example.com/app/login?error=saml-authentication-failed&sso_account_id=#{account.id}")
        expect(existing_user.reload.provider).to eq('email')
        expect(existing_user.accounts).not_to include(account)
      end
    end
  end
end
