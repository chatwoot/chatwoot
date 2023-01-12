require 'rails_helper'

RSpec.describe 'Microsoft Authorization API', type: :request do
  let(:account) { create(:account) }

  describe 'POST /api/v1/accounts/{account.id}/microsoft/authorization' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        post "/api/v1/accounts/#{account.id}/microsoft/authorization"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      let(:agent) { create(:user, account: account, role: :agent) }
      let(:administrator) { create(:user, account: account, role: :administrator) }
      let(:microsoft_client) do
        OAuth2::Client.new('client_id', 'client_secret', {
                             site: 'https://login.microsoftonline.com',
                             authorize_url: 'https://login.microsoftonline.com/common/oauth2/v2.0/authorize'
                           })
      end
      let(:auth_code) { microsoft_client.auth_code }
      let(:raw_response) { double }

      it 'returns unathorized for agent' do
        post "/api/v1/accounts/#{account.id}/microsoft/authorization",
             headers: agent.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:unauthorized)
      end

      it 'creates a new authorization and returns the redirect url' do
        allow(::OAuth2::Client).to receive(:new).and_return(microsoft_client)
        allow(microsoft_client).to receive(:auth_code).and_return(auth_code)
        allow(auth_code).to receive(:authorize_url).and_return(
          microsoft_client.authorize_url({ redirect_uri: 'http:0.0.0.0:3000/microsoft/callback' })
        )

        post "/api/v1/accounts/#{account.id}/microsoft/authorization",
             headers: administrator.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:success)
        expect(JSON.parse(response.body)['url']).to include('microsoft')
      end
    end
  end
end
