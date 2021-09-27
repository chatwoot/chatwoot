require 'rails_helper'

RSpec.describe 'Agents API', type: :request do
  let(:account) { create(:account) }
  let(:admin) { create(:user, custom_attributes: { test: 'test' }, account: account, role: :administrator) }
  let(:agent) { create(:user, account: account, role: :agent) }

  describe 'GET /api/v1/accounts/{account.id}/agents' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get "/api/v1/accounts/#{account.id}/agents"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      let!(:agent) { create(:user, account: account, role: :agent) }

      it 'returns all agents of account' do
        get "/api/v1/accounts/#{account.id}/agents",
            headers: agent.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        expect(JSON.parse(response.body).size).to eq(account.users.count)
      end

      it 'returns custom fields on agents if present' do
        agent.update(custom_attributes: { test: 'test' })

        get "/api/v1/accounts/#{account.id}/agents",
            headers: agent.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        data = JSON.parse(response.body)
        expect(data.first['custom_attributes']['test']).to eq('test')
      end
    end
  end

  describe 'DELETE /api/v1/accounts/{account.id}/agents/:id' do
    let(:other_agent) { create(:user, account: account, role: :agent) }

    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        delete "/api/v1/accounts/#{account.id}/agents/#{other_agent.id}"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      it 'returns unauthorized for agents' do
        delete "/api/v1/accounts/#{account.id}/agents/#{other_agent.id}",
               headers: agent.create_new_auth_token,
               as: :json

        expect(response).to have_http_status(:unauthorized)
      end

      it 'deletes an agent' do
        delete "/api/v1/accounts/#{account.id}/agents/#{other_agent.id}",
               headers: admin.create_new_auth_token,
               as: :json

        expect(response).to have_http_status(:success)
        expect(account.users.size).to eq(1)
      end
    end
  end

  describe 'PUT /api/v1/accounts/{account.id}/agents/:id' do
    let(:other_agent) { create(:user, account: account, role: :agent) }

    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        put "/api/v1/accounts/#{account.id}/agents/#{other_agent.id}"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      params = { name: 'TestUser' }

      it 'returns unauthorized for agents' do
        put "/api/v1/accounts/#{account.id}/agents/#{other_agent.id}",
            params: params,
            headers: agent.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:unauthorized)
      end

      it 'modifies an agent name' do
        put "/api/v1/accounts/#{account.id}/agents/#{other_agent.id}",
            params: params,
            headers: admin.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        expect(other_agent.reload.name).to eq(params[:name])
      end

      it 'modifies an agents account user attributes' do
        put "/api/v1/accounts/#{account.id}/agents/#{other_agent.id}",
            params: { role: 'administrator', availability: 'busy', auto_offline: false },
            headers: admin.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        response_data = JSON.parse(response.body)
        expect(response_data['role']).to eq('administrator')
        expect(response_data['availability_status']).to eq('busy')
        expect(response_data['auto_offline']).to eq(false)
        expect(other_agent.account_users.first.role).to eq('administrator')
      end
    end
  end

  describe 'POST /api/v1/accounts/{account.id}/agents' do
    let(:other_agent) { create(:user, account: account, role: :agent) }

    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        post "/api/v1/accounts/#{account.id}/agents"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      params = { name: 'NewUser', email: Faker::Internet.email, role: :agent }

      it 'returns unauthorized for agents' do
        post "/api/v1/accounts/#{account.id}/agents",
             params: params,
             headers: agent.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:unauthorized)
      end

      it 'creates a new agent' do
        post "/api/v1/accounts/#{account.id}/agents",
             params: params,
             headers: admin.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:success)
        expect(account.users.last.name).to eq('NewUser')
      end
    end
  end
end
