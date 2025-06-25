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
        post "/api/v1/accounts/#{account.id}/instagram/authorization",
             headers: administrator.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:success)
        expect(response.parsed_body['success']).to be true

        instagram_service = Class.new do
          extend InstagramConcern
          extend Instagram::IntegrationHelper
        end
        frontend_url = ENV.fetch('FRONTEND_URL', 'http://localhost:3000')
        response_url = instagram_service.instagram_client.auth_code.authorize_url(
          {
            redirect_uri: "#{frontend_url}/instagram/callback",
            scope: Instagram::IntegrationHelper::REQUIRED_SCOPES.join(','),
            enable_fb_login: '0',
            force_authentication: '1',
            response_type: 'code',
            state: instagram_service.generate_instagram_token(account.id)
          }
        )
        expect(response.parsed_body['url']).to eq response_url
      end
    end
  end
end
