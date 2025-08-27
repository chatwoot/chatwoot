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

      it 'successfully logs in the user' do
        post "/auth/saml/#{account.id}/callback",
             env: { 'omniauth.auth' => auth_hash },
             as: :json

        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        expect(json_response['message']).to eq('Login successful')
        expect(json_response['user']['email']).to eq('john.doe@example.com')
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
