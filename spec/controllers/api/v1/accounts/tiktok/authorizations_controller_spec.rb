require 'rails_helper'

RSpec.describe 'TikTok Authorization API', type: :request do
  let(:account) { create(:account) }

  describe 'POST /api/v1/accounts/{account.id}/tiktok/authorization' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        post "/api/v1/accounts/#{account.id}/tiktok/authorization"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      let(:agent) { create(:user, account: account, role: :agent) }
      let(:administrator) { create(:user, account: account, role: :administrator) }

      before do
        InstallationConfig.where(name: %w[TIKTOK_APP_ID TIKTOK_APP_SECRET]).delete_all
        GlobalConfig.clear_cache
      end

      it 'returns unauthorized for agent' do
        with_modified_env TIKTOK_APP_ID: 'tiktok-app-id', TIKTOK_APP_SECRET: 'tiktok-app-secret' do
          post "/api/v1/accounts/#{account.id}/tiktok/authorization",
               headers: agent.create_new_auth_token,
               as: :json
        end

        expect(response).to have_http_status(:unauthorized)
      end

      it 'creates a new authorization and returns the redirect url' do
        with_modified_env TIKTOK_APP_ID: 'tiktok-app-id', TIKTOK_APP_SECRET: 'tiktok-app-secret' do
          post "/api/v1/accounts/#{account.id}/tiktok/authorization",
               headers: administrator.create_new_auth_token,
               as: :json
        end

        expect(response).to have_http_status(:success)
        expect(response.parsed_body['success']).to be true

        helper = Class.new do
          include Tiktok::IntegrationHelper
        end.new

        expected_state = helper.generate_tiktok_token(account.id)
        expected_url = Tiktok::AuthClient.authorize_url(state: expected_state)

        expect(response.parsed_body['url']).to eq(expected_url)
      end
    end
  end
end
