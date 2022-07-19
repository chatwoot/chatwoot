require 'rails_helper'

RSpec.describe 'Api::V1::Accounts::MacrosController', type: :request do
  let(:account) { create(:account) }
  let(:administrator) { create(:user, account: account, role: :administrator) }
  let(:agent) { create(:user, account: account, role: :agent) }
  let(:agent_1) { create(:user, account: account, role: :agent) }

  before do
    create(:macro, account: account, created_by: administrator, updated_by: administrator, visibility: :global)
    create(:macro, account: account, created_by: administrator, updated_by: administrator, visibility: :global)
    create(:macro, account: account, created_by: administrator, updated_by: administrator, visibility: :personal)
    create(:macro, account: account, created_by: agent, updated_by: agent, visibility: :personal)
    create(:macro, account: account, created_by: agent, updated_by: agent, visibility: :personal)
    create(:macro, account: account, created_by: agent_1, updated_by: agent_1, visibility: :personal)
  end

  describe 'GET /api/v1/accounts/{account.id}/macros' do
    context 'when it is an authenticated administrator' do
      it 'returns all records in the account' do
        get "/api/v1/accounts/#{account.id}/macros",
            headers: administrator.create_new_auth_token

        visible_macros = account.macros

        expect(response).to have_http_status(:success)
        body = JSON.parse(response.body)

        expect(body['payload'].length).to eq(visible_macros.count)
        expect(body['payload'].first['id']).to eq(Macro.first.id)
        expect(body['payload'].last['id']).to eq(Macro.last.id)
      end
    end

    context 'when it is an authenticated agent' do
      it 'returns all records in account and created_by the agent' do
        get "/api/v1/accounts/#{account.id}/macros",
            headers: agent.create_new_auth_token

        expect(response).to have_http_status(:success)

        body = JSON.parse(response.body)
        visible_macros = account.macros.global.or(account.macros.personal.where(created_by_id: agent.id))

        expect(body['payload'].length).to eq(visible_macros.count)
        expect(body['payload'].first['id']).to eq(visible_macros.first.id)
        expect(body['payload'].last['id']).to eq(visible_macros.last.id)
      end
    end

    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        post "/api/v1/accounts/#{account.id}/macros"

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe 'POST /api/v1/accounts/{account.id}/macros' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        post "/api/v1/accounts/#{account.id}/macros"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      let(:params) do
        {
          'name': 'Add label, send message and close the chat',
          'actions': [
            {
              'action_name': :add_label,
              'action_params': %w[support priority_customer]
            },
            {
              'action_name': :send_message,
              'action_params': ['Welcome to the chatwoot platform.']
            },
            {
              'action_name': :resolved
            }
          ],
          visibility: 'global',
          created_by_id: administrator.id
        }.with_indifferent_access
      end

      it 'creates the macro' do
        post "/api/v1/accounts/#{account.id}/macros",
             params: params,
             headers: administrator.create_new_auth_token

        expect(response).to have_http_status(:success)

        json_response = JSON.parse(response.body)

        expect(json_response['payload']['name']).to eql(params['name'])
        expect(json_response['payload']['visibility']).to eql(params['visibility'])
        expect(json_response['payload']['created_by']['id']).to eql(administrator.id)
      end

      it 'sets visibility default to personal for agent' do
        post "/api/v1/accounts/#{account.id}/macros",
             params: params,
             headers: agent.create_new_auth_token

        expect(response).to have_http_status(:success)

        json_response = JSON.parse(response.body)

        expect(json_response['payload']['name']).to eql(params['name'])
        expect(json_response['payload']['visibility']).to eql('personal')
        expect(json_response['payload']['created_by']['id']).to eql(agent.id)
      end
    end
  end

  describe 'PUT /api/v1/accounts/{account.id}/macros/{macro.id}' do
    let!(:macro) { create(:macro, account: account, created_by: administrator, updated_by: administrator) }

    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        put "/api/v1/accounts/#{account.id}/macros/#{macro.id}"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      let(:params) do
        {
          'name': 'Add label, send message and close the chat'
        }
      end

      it 'Updates the macro' do
        put "/api/v1/accounts/#{account.id}/macros/#{macro.id}",
            params: params,
            headers: administrator.create_new_auth_token

        expect(response).to have_http_status(:success)
        json_response = JSON.parse(response.body)
        expect(json_response['name']).to eql(params['name'])
      end
    end
  end

  describe 'GET /api/v1/accounts/{account.id}/macros/{macro.id}' do
    let!(:macro) { create(:macro, account: account, created_by: administrator, updated_by: administrator) }

    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get "/api/v1/accounts/#{account.id}/macros/#{macro.id}"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      it 'fetch the macro' do
        get "/api/v1/accounts/#{account.id}/macros/#{macro.id}",
            headers: administrator.create_new_auth_token

        expect(response).to have_http_status(:success)

        json_response = JSON.parse(response.body)

        expect(json_response['payload']['name']).to eql(macro.name)
        expect(json_response['payload']['created_by']['id']).to eql(administrator.id)
      end
    end
  end
end
