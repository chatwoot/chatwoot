require 'rails_helper'

RSpec.describe 'Google Authorization API', type: :request do
  let(:account) { create(:account) }

  describe 'POST /api/v1/accounts/{account.id}/google/authorization' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        post "/api/v1/accounts/#{account.id}/google/authorization"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      let(:agent) { create(:user, account: account, role: :agent) }
      let(:administrator) { create(:user, account: account, role: :administrator) }

      it 'returns unathorized for agent' do
        post "/api/v1/accounts/#{account.id}/google/authorization",
             headers: agent.create_new_auth_token,
             params: { email: administrator.email },
             as: :json

        expect(response).to have_http_status(:unauthorized)
      end

      it 'creates a new authorization and returns the redirect url' do
        post "/api/v1/accounts/#{account.id}/google/authorization",
             headers: administrator.create_new_auth_token,
             params: { email: administrator.email },
             as: :json

        expect(response).to have_http_status(:success)
        google_service = Class.new { extend GoogleConcern }
        response_url = google_service.google_client.auth_code.authorize_url(
          {
            redirect_uri: "#{ENV.fetch('FRONTEND_URL', 'http://localhost:3000')}/google/callback",
            scope: 'email profile https://mail.google.com/',
            response_type: 'code',
            prompt: 'consent',
            access_type: 'offline',
            client_id: GlobalConfigService.load('GOOGLE_OAUTH_CLIENT_ID', nil)
          }
        )
        expect(response.parsed_body['url']).to eq response_url
        expect(Redis::Alfred.get("google::#{administrator.email}")).to eq(account.id.to_s)
      end
    end
  end
end
