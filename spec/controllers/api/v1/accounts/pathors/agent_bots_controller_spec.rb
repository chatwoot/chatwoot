require 'rails_helper'

RSpec.describe 'Pathors Agent Bots API', type: :request do
  let(:account) { create(:account) }
  let(:admin) { create(:user, account: account, role: :administrator) }
  let(:agent) { create(:user, account: account, role: :agent) }

  describe 'GET /api/v1/accounts/{account.id}/pathors/agent_bots' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get "/api/v1/accounts/#{account.id}/pathors/agent_bots"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an administrator' do
      it 'returns the Pathors bots with the project they answer for' do
        pathors_bot = create(:agent_bot, account: account, name: 'Pathors Agent',
                                         outgoing_url: 'https://api.pathors.com/project/proj_123/integration/chatwoot/callback')

        get "/api/v1/accounts/#{account.id}/pathors/agent_bots", headers: admin.create_new_auth_token, as: :json

        expect(response).to have_http_status(:success)
        expect(response.parsed_body['payload']).to eq(
          [{ 'id' => pathors_bot.id, 'name' => 'Pathors Agent', 'project_id' => 'proj_123' }]
        )
      end

      it 'excludes bots that are not Pathors bots' do
        create(:agent_bot, account: account, outgoing_url: 'https://example.com/webhook')

        get "/api/v1/accounts/#{account.id}/pathors/agent_bots", headers: admin.create_new_auth_token, as: :json

        expect(response.parsed_body['payload']).to be_empty
      end

      it 'excludes bots from another account' do
        create(:agent_bot, account: create(:account),
                           outgoing_url: 'https://api.pathors.com/project/proj_123/integration/chatwoot/callback')

        get "/api/v1/accounts/#{account.id}/pathors/agent_bots", headers: admin.create_new_auth_token, as: :json

        expect(response.parsed_body['payload']).to be_empty
      end
    end

    context 'when it is an agent' do
      it 'returns unauthorized' do
        get "/api/v1/accounts/#{account.id}/pathors/agent_bots", headers: agent.create_new_auth_token, as: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an agent bot' do
      it 'returns unauthorized' do
        get "/api/v1/accounts/#{account.id}/pathors/agent_bots",
            headers: { api_access_token: create(:agent_bot, account: account).access_token.token }, as: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end
