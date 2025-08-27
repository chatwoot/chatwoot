require 'rails_helper'

RSpec.describe 'SAML Authentication API', type: :request do
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

  describe 'POST /auth/saml/:account_id/callback' do
    context 'with existing user' do
      let(:auth_hash) do
        {
          'provider' => 'saml',
          'uid' => 'john.doe@example.com',
          'info' => {
            'email' => 'john.doe@example.com',
            'name' => 'John Doe'
          }
        }
      end

      before do
        existing_user
      end

      it 'redirects to frontend login with SSO token' do
        post "/auth/saml/#{account.id}/callback",
             env: { 'omniauth.auth' => auth_hash },
             as: :json

        expect(response).to have_http_status(:found) # 302 redirect
        expect(response.location).to include('/app/login')
        expect(response.location).to include('email=john.doe%40example.com')
        expect(response.location).to include('sso_auth_token=')
      end

      it 'generates SSO auth token for the user' do
        expect(existing_user).to receive(:generate_sso_auth_token).and_call_original

        post "/auth/saml/#{account.id}/callback",
             env: { 'omniauth.auth' => auth_hash },
             as: :json

        # Verify token was created in Redis
        expect(response).to have_http_status(:found)
      end

      it 'does not update sign in tracking directly' do
        # Sign in tracking should happen when user completes login via frontend
        expect do
          post "/auth/saml/#{account.id}/callback",
               env: { 'omniauth.auth' => auth_hash },
               as: :json
        end.not_to change { existing_user.reload.sign_in_count }
      end
    end

    context 'when user does not exist' do
      let(:auth_hash) do
        {
          'provider' => 'saml',
          'uid' => 'nonexistent@example.com',
          'info' => {
            'email' => 'nonexistent@example.com'
          }
        }
      end

      it 'returns user not found error' do
        post "/auth/saml/#{account.id}/callback",
             env: { 'omniauth.auth' => auth_hash },
             as: :json

        expect(response).to have_http_status(:not_found)
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to eq('User not found')
      end
    end
  end
end
