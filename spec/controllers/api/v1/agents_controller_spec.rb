require 'rails_helper'

RSpec.describe 'Agents API', type: :request do
  let(:account) { create(:account) }
  let(:administrator) { create(:user, account: account, role: :administrator) }

  describe 'GET /api/v1/agents' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get '/api/v1/agents'

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      it 'returns all the agents' do
        get '/api/v1/agents',
            headers: administrator.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        expect(response.body).to include(administrator.name)
      end
    end
  end

  describe 'POST /api/v1/agents' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        post '/api/v1/agents'

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      it 'creates a new canned response' do
        params = { name: 'test 123', email: '123@test.com', role: 'administrator' }

        post '/api/v1/agents',
             params: params,
             headers: administrator.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:success)
        expect(User.count).to eq(2)
      end
    end
  end

  describe 'PUT /api/v1/agents/:id' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        put "/api/v1/agents/#{administrator.id}"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      it 'updates an existing canned response' do
        params = { name: 'Test 123' }

        put "/api/v1/agents/#{administrator.id}",
            params: params,
            headers: administrator.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        expect(administrator.reload.name).to eq('Test 123')
      end
    end
  end
end
