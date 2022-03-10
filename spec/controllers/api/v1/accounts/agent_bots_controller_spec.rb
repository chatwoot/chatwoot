require 'rails_helper'

RSpec.describe 'Agent Bot API', type: :request do
  let!(:account) { create(:account) }
  let!(:agent_bot) { create(:agent_bot, account: account) }
  let(:admin) { create(:user, account: account, role: :administrator) }
  let(:agent) { create(:user, account: account, role: :agent) }

  describe 'GET /api/v1/accounts/{account.id}/agent_bots' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get "/api/v1/accounts/#{account.id}/agent_bots"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      it 'returns all the agent_bots in account along with global agent bots' do
        global_bot = create(:agent_bot)
        get "/api/v1/accounts/#{account.id}/agent_bots",
            headers: agent.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        expect(response.body).to include(agent_bot.name)
        expect(response.body).to include(global_bot.name)
        expect(response.body).to include(agent_bot.access_token.token)
        expect(response.body).not_to include(global_bot.access_token.token)
      end
    end
  end

  describe 'GET /api/v1/accounts/{account.id}/agent_bots/:id' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get "/api/v1/accounts/#{account.id}/agent_bots/#{agent_bot.id}"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      it 'shows the agent bot' do
        get "/api/v1/accounts/#{account.id}/agent_bots/#{agent_bot.id}",
            headers: agent.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        expect(response.body).to include(agent_bot.name)
        expect(response.body).to include(agent_bot.access_token.token)
      end

      it 'will show a global agent bot' do
        global_bot = create(:agent_bot)
        get "/api/v1/accounts/#{account.id}/agent_bots/#{global_bot.id}",
            headers: agent.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        expect(response.body).to include(global_bot.name)
        expect(response.body).not_to include(global_bot.access_token.token)
      end
    end
  end

  describe 'POST /api/v1/accounts/{account.id}/agent_bots' do
    let(:valid_params) { { name: 'test' } }

    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        expect { post "/api/v1/accounts/#{account.id}/agent_bots", params: valid_params }.to change(Label, :count).by(0)

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      it 'creates the agent bot when administrator' do
        expect do
          post "/api/v1/accounts/#{account.id}/agent_bots", headers: admin.create_new_auth_token,
                                                            params: valid_params
        end.to change(AgentBot, :count).by(1)

        expect(response).to have_http_status(:success)
      end

      it 'would not create the agent bot when agent' do
        expect do
          post "/api/v1/accounts/#{account.id}/agent_bots", headers: agent.create_new_auth_token,
                                                            params: valid_params
        end.to change(AgentBot, :count).by(0)

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe 'PATCH /api/v1/accounts/{account.id}/agent_bots/:id' do
    let(:valid_params) { { name: 'test_updated' } }

    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        patch "/api/v1/accounts/#{account.id}/agent_bots/#{agent_bot.id}",
              params: valid_params

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      it 'updates the agent bot' do
        patch "/api/v1/accounts/#{account.id}/agent_bots/#{agent_bot.id}",
              headers: admin.create_new_auth_token,
              params: valid_params,
              as: :json

        expect(response).to have_http_status(:success)
        expect(agent_bot.reload.name).to eq('test_updated')
        expect(response.body).to include(agent_bot.access_token.token)
      end

      it 'would not update the agent bot when agent' do
        patch "/api/v1/accounts/#{account.id}/agent_bots/#{agent_bot.id}",
              headers: agent.create_new_auth_token,
              params: valid_params,
              as: :json

        expect(response).to have_http_status(:unauthorized)
        expect(agent_bot.reload.name).not_to eq('test_updated')
      end

      it 'would not update a global agent bot' do
        global_bot = create(:agent_bot)
        patch "/api/v1/accounts/#{account.id}/agent_bots/#{global_bot.id}",
              headers: admin.create_new_auth_token,
              params: valid_params,
              as: :json

        expect(response).to have_http_status(:not_found)
        expect(agent_bot.reload.name).not_to eq('test_updated')
        expect(response.body).not_to include(global_bot.access_token.token)
      end
    end
  end

  describe 'DELETE /api/v1/accounts/{account.id}/agent_bots/:id' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        delete "/api/v1/accounts/#{account.id}/agent_bots/#{agent_bot.id}"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      it 'deletes an agent bot when administrator' do
        delete "/api/v1/accounts/#{account.id}/agent_bots/#{agent_bot.id}",
               headers: admin.create_new_auth_token,
               as: :json

        expect(response).to have_http_status(:success)
        expect(account.agent_bots.size).to eq(0)
      end

      it 'would not delete the agent bot when agent' do
        delete "/api/v1/accounts/#{account.id}/agent_bots/#{agent_bot.id}",
               headers: agent.create_new_auth_token,
               as: :json

        expect(response).to have_http_status(:unauthorized)
        expect(account.agent_bots.size).not_to eq(0)
      end

      it 'would not delete a global agent bot' do
        global_bot = create(:agent_bot)
        delete "/api/v1/accounts/#{account.id}/agent_bots/#{global_bot.id}",
               headers: admin.create_new_auth_token,
               as: :json

        expect(response).to have_http_status(:not_found)
        expect(account.agent_bots.size).not_to eq(0)
      end
    end
  end
end
