require 'rails_helper'

RSpec.describe 'Platform Agent Bot API', type: :request do
  let!(:agent_bot) { create(:agent_bot) }

  describe 'GET /platform/api/v1/agent_bots' do
    context 'when it is an unauthenticated platform app' do
      it 'returns unauthorized' do
        get '/platform/api/v1/agent_bots'
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an invalid platform app token' do
      it 'returns unauthorized' do
        get '/platform/api/v1/agent_bots', headers: { api_access_token: 'invalid' }, as: :json
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated platform app' do
      let(:platform_app) { create(:platform_app) }

      it 'returns unauthorized when its not a permissible object' do
        get '/platform/api/v1/agent_bots', headers: { api_access_token: platform_app.access_token.token }, as: :json
        expect(response).to have_http_status(:success)
        data = JSON.parse(response.body)
        expect(data.length).to eq(0)
      end

      it 'shows a agent_bot when its permissible object' do
        create(:platform_app_permissible, platform_app: platform_app, permissible: agent_bot)

        get '/platform/api/v1/agent_bots',
            headers: { api_access_token: platform_app.access_token.token }, as: :json

        expect(response).to have_http_status(:success)
        data = JSON.parse(response.body)
        expect(data.length).to eq(1)
      end
    end
  end

  describe 'GET /platform/api/v1/agent_bots/{agent_bot_id}' do
    context 'when it is an unauthenticated platform app' do
      it 'returns unauthorized' do
        get "/platform/api/v1/agent_bots/#{agent_bot.id}"
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an invalid platform app token' do
      it 'returns unauthorized' do
        get "/platform/api/v1/agent_bots/#{agent_bot.id}", headers: { api_access_token: 'invalid' }, as: :json
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated platform app' do
      let(:platform_app) { create(:platform_app) }

      it 'returns unauthorized when its not a permissible object' do
        get "/platform/api/v1/agent_bots/#{agent_bot.id}", headers: { api_access_token: platform_app.access_token.token }, as: :json
        expect(response).to have_http_status(:unauthorized)
      end

      it 'shows a agent_bot when its permissible object' do
        create(:platform_app_permissible, platform_app: platform_app, permissible: agent_bot)

        get "/platform/api/v1/agent_bots/#{agent_bot.id}",
            headers: { api_access_token: platform_app.access_token.token }, as: :json

        expect(response).to have_http_status(:success)
        data = JSON.parse(response.body)
        expect(data['name']).to eq(agent_bot.name)
      end
    end
  end

  describe 'POST /platform/api/v1/agent_bots/' do
    context 'when it is an unauthenticated platform app' do
      it 'returns unauthorized' do
        post '/platform/api/v1/agent_bots'
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an invalid platform app token' do
      it 'returns unauthorized' do
        post '/platform/api/v1/agent_bots/', headers: { api_access_token: 'invalid' }, as: :json
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated platform app' do
      let(:platform_app) { create(:platform_app) }

      it 'creates a new agent bot' do
        post '/platform/api/v1/agent_bots/', params: { name: 'test' },
                                             headers: { api_access_token: platform_app.access_token.token }, as: :json

        expect(response).to have_http_status(:success)
        data = JSON.parse(response.body)
        expect(data['name']).to eq('test')
        expect(platform_app.platform_app_permissibles.first.permissible_id).to eq data['id']
      end
    end
  end

  describe 'PATCH /platform/api/v1/agent_bots/{agent_bot_id}' do
    context 'when it is an unauthenticated platform app' do
      it 'returns unauthorized' do
        patch "/platform/api/v1/agent_bots/#{agent_bot.id}"
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an invalid platform app token' do
      it 'returns unauthorized' do
        patch "/platform/api/v1/agent_bots/#{agent_bot.id}", headers: { api_access_token: 'invalid' }, as: :json
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated platform app' do
      let(:platform_app) { create(:platform_app) }

      it 'returns unauthorized when its not a permissible object' do
        patch "/platform/api/v1/agent_bots/#{agent_bot.id}", params: { name: 'test' },
                                                             headers: { api_access_token: platform_app.access_token.token }, as: :json
        expect(response).to have_http_status(:unauthorized)
      end

      it 'updates the agent_bot' do
        create(:platform_app_permissible, platform_app: platform_app, permissible: agent_bot)
        patch "/platform/api/v1/agent_bots/#{agent_bot.id}", params: { name: 'test123' },
                                                             headers: { api_access_token: platform_app.access_token.token }, as: :json

        expect(response).to have_http_status(:success)
        data = JSON.parse(response.body)
        expect(data['name']).to eq('test123')
      end
    end
  end

  describe 'DELETE /platform/api/v1/agent_bots/{agent_bot_id}' do
    context 'when it is an unauthenticated platform app' do
      it 'returns unauthorized' do
        delete "/platform/api/v1/agent_bots/#{agent_bot.id}", headers: { api_access_token: 'invalid' }, as: :json
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated platform app' do
      let(:platform_app) { create(:platform_app) }

      it 'returns unauthorized when its not a permissible object' do
        delete "/platform/api/v1/agent_bots/#{agent_bot.id}", headers: { api_access_token: 'invalid' }, as: :json
        expect(response).to have_http_status(:unauthorized)
      end

      it 'returns deletes the account user' do
        create(:platform_app_permissible, platform_app: platform_app, permissible: agent_bot)

        delete "/platform/api/v1/agent_bots/#{agent_bot.id}", headers: { api_access_token: platform_app.access_token.token }, as: :json

        expect(response).to have_http_status(:success)
        expect(AgentBot.count).to eq 0
      end
    end
  end
end
