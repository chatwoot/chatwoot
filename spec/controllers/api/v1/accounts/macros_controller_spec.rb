require 'rails_helper'

RSpec.describe 'Api::V1::Accounts::MacrosController', type: :request do
  include ActiveJob::TestHelper

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
              'action_name': :resolve_conversation
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

      it 'return not_found status when macros not available' do
        get "/api/v1/accounts/#{account.id}/macros/15",
            headers: administrator.create_new_auth_token

        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe 'POST /api/v1/accounts/{account.id}/macros/{macro.id}/execute' do
    let!(:macro) { create(:macro, account: account, created_by: administrator, updated_by: administrator) }
    let(:inbox) { create(:inbox, account: account) }
    let(:contact) { create(:contact, account: account, identifier: '123') }
    let(:conversation) { create(:conversation, inbox: inbox, account: account, status: :open) }
    let(:team) { create(:team, account: account) }
    let(:user_1) { create(:user, role: 0) }

    before do
      create(:team_member, user: user_1, team: team)
      create(:account_user, user: user_1, account: account)
      macro.update!(actions:
                              [
                                {
                                  'action_name' => 'send_email_to_team', 'action_params' => [{
                                    'message' => 'Please pay attention to this conversation, its from high priority customer',
                                    'team_ids' => [team.id]
                                  }]
                                },
                                { 'action_name' => 'assign_team', 'action_params' => [team.id] },
                                { 'action_name' => 'add_label', 'action_params' => %w[support priority_customer] },
                                { 'action_name' => 'snooze_conversation' },
                                { 'action_name' => 'assign_best_agent', 'action_params' => [user_1.id] },
                                { 'action_name' => 'send_message', 'action_params' => ['Send this message.'] }
                              ])
    end

    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        post "/api/v1/accounts/#{account.id}/macros/#{macro.id}/execute"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      it 'execute the macro' do
        expect(conversation.messages).to be_empty
        expect(conversation.assignee).to be_nil
        expect(conversation.labels).to be_empty

        perform_enqueued_jobs do
          post "/api/v1/accounts/#{account.id}/macros/#{macro.id}/execute",
               params: { conversation_ids: [conversation.display_id] },
               headers: administrator.create_new_auth_token
        end

        expect(conversation.reload.status).to eql('snoozed')
        expect(conversation.messages.chat.last.content).to eq('Send this message.')
        expect(conversation.label_list).to match_array(%w[support priority_customer])
        expect(conversation.messages.activity.last.content).to eq("Assigned to #{user_1.name} by #{administrator.name}")
      end
    end
  end
end
