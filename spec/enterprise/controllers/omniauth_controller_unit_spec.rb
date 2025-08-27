require 'rails_helper'

RSpec.describe OmniauthController, type: :controller do
  let(:account) { create(:account) }
  let!(:saml_settings) do
    create(:account_saml_settings,
           :enabled,
           account: account,
           sso_url: 'https://mocksaml.com/sso')
  end
  let(:existing_user) do
    create(:user, email: 'john.doe@example.com', name: 'John Doe')
  end

  describe 'GET #callback' do
    context 'with existing user' do
      let(:auth_hash) do
        OmniAuth::AuthHash.new({
          provider: 'saml',
          uid: 'john.doe@example.com',
          info: {
            email: 'john.doe@example.com',
            name: 'John Doe',
            first_name: 'John',
            last_name: 'Doe'
          }
        })
      end

      before do
        existing_user
        # Mock the OmniAuth auth hash in the request environment
        request.env['omniauth.auth'] = auth_hash
      end

      it 'redirects to frontend login with SSO token' do
        get :callback, params: { account_id: account.id }

        expect(response).to have_http_status(:found)
        expect(response.location).to include('/app/login')
        expect(response.location).to include('email=john.doe%40example.com')
        expect(response.location).to include('sso_auth_token=')
      end

      it 'generates a valid SSO auth token' do
        allow(SecureRandom).to receive(:hex).and_return('test_token_12345')
        
        get :callback, params: { account_id: account.id }

        # Verify token was stored in Redis
        token_key = "chatwoot:user:#{existing_user.id}:sso_auth_token:test_token_12345"
        expect(::Redis::Alfred.get(token_key)).to eq('true')
      end
    end

    context 'when user does not exist' do
      let(:auth_hash) do
        OmniAuth::AuthHash.new({
          provider: 'saml',
          uid: 'newuser@example.com',
          info: {
            email: 'newuser@example.com',
            name: 'New User'
          }
        })
      end

      before do
        request.env['omniauth.auth'] = auth_hash
      end

      it 'returns user not found error' do
        get :callback, params: { account_id: account.id }

        expect(response).to have_http_status(:not_found)
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to eq('User not found')
        expect(json_response['message']).to include('newuser@example.com')
      end
    end

    context 'when SAML is not enabled for account' do
      before do
        saml_settings.update!(enabled: false)
        request.env['omniauth.auth'] = { info: { email: 'test@example.com' } }
      end

      it 'returns unauthorized error' do
        get :callback, params: { account_id: account.id }

        expect(response).to have_http_status(:unauthorized)
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to eq('SAML not enabled for this account')
      end
    end

    context 'when authentication fails' do
      before do
        request.env['omniauth.auth'] = nil
        request.env['omniauth.error'] = 'Invalid SAML Response'
      end

      it 'returns authentication failed error' do
        get :callback, params: { account_id: account.id }

        expect(response).to have_http_status(:unauthorized)
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to eq('SAML authentication failed')
        expect(json_response['message']).to eq('Invalid SAML Response')
      end
    end
  end

  describe 'GET #failure' do
    it 'returns authentication failure message' do
      get :failure, params: { message: 'SAML IdP error occurred' }

      expect(response).to have_http_status(:unauthorized)
      json_response = JSON.parse(response.body)
      expect(json_response['error']).to eq('SAML authentication failed')
      expect(json_response['message']).to eq('SAML IdP error occurred')
    end
  end
end