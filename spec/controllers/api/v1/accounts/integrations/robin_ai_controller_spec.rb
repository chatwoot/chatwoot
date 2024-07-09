require 'rails_helper'

RSpec.describe 'Robin AI Integrations API', type: :request do
  let(:account) { create(:account) }
  let(:admin) { create(:user, account: account, role: :administrator) }
  let(:agent) { create(:user, account: account, role: :agent) }
  let(:inbox) { create(:inbox, account: account) }

  describe 'POST /api/v1/accounts/{account.id}/integrations/robin_ai/generate_sso_url' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        post generate_sso_url_api_v1_account_integrations_robin_ai_url(account_id: account.id),
             params: {},
             as: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      it 'return unauthorized if agent' do
        post generate_sso_url_api_v1_account_integrations_robin_ai_url(account_id: account.id),
             params: {},
             headers: agent.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:unauthorized)
      end

      it 'creates hooks if admin' do
        stub_request(:post, ENV.fetch('ROBIN_AI_SSO_URL', '')).to_return(
          status: 200,
          body: { sso_url: 'https://robin.ai/sso' }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

        post generate_sso_url_api_v1_account_integrations_robin_ai_url(account_id: account.id),
             params: {},
             headers: admin.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:success)
        data = response.parsed_body
        expect(data['sso_url'].present?).to be(true)
      end
    end
  end
end
