require 'rails_helper'

RSpec.describe 'Instagram Authorization API', type: :request do
  let(:account) { create(:account) }

  describe 'POST /api/v1/accounts/{account.id}/instagram/authorization' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        post "/api/v1/accounts/#{account.id}/instagram/authorization"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      let(:agent) { create(:user, account: account, role: :agent) }
      let(:administrator) { create(:user, account: account, role: :administrator) }

      it 'returns unauthorized for agent' do
        post "/api/v1/accounts/#{account.id}/instagram/authorization",
             headers: agent.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:unauthorized)
      end

      it 'creates a new authorization and returns the redirect url' do
        mock_url = 'https://api.instagram.com/oauth/authorize?mock=true'
        auth_code_double = instance_double(OAuth2::Strategy::AuthCode)
        allow(auth_code_double).to receive(:authorize_url).and_return(mock_url)

        client_double = instance_double(OAuth2::Client)
        allow(client_double).to receive(:auth_code).and_return(auth_code_double)

        allow_any_instance_of(Api::V1::Accounts::Instagram::AuthorizationsController)
          .to receive(:instagram_client)
          .and_return(client_double)

        post "/api/v1/accounts/#{account.id}/instagram/authorization",
             headers: administrator.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:success)
        expect(response.parsed_body['success']).to be true
        expect(response.parsed_body['url']).to eq mock_url
      end
    end
  end
end
