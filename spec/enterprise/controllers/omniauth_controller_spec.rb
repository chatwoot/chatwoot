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
        expect(json_response['data']).to be_present
        expect(json_response['data']['email']).to eq('john.doe@example.com')
        expect(json_response['data']['id']).to eq(existing_user.id)
      end

      it 'creates authentication tokens for the user' do
        expect do
          post "/auth/saml/#{account.id}/callback",
               env: { 'omniauth.auth' => auth_hash },
               as: :json
        end.to change { existing_user.reload.tokens.count }.by(1)
      end

      it 'updates user sign in tracking' do
        existing_user

        expect do
          post "/auth/saml/#{account.id}/callback",
               env: { 'omniauth.auth' => auth_hash },
               as: :json
        end.to change { existing_user.reload.sign_in_count }.by(1)

        expect(existing_user.reload.current_sign_in_at).to be_present
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
