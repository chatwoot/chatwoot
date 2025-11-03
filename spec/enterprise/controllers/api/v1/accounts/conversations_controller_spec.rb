require 'rails_helper'

RSpec.describe 'Conversations API', type: :request do
  let(:account) { create(:account) }
  let(:administrator) { create(:user, account: account, role: :administrator) }

  describe 'GET /api/v1/accounts/{account.id}/conversations/:id' do
    it 'returns SLA data for the conversation if the feature is enabled' do
      account.enable_features!('sla')
      conversation = create(:conversation, account: account)
      applied_sla = create(:applied_sla, conversation: conversation)
      sla_event = create(:sla_event, conversation: conversation, applied_sla: applied_sla)

      get "/api/v1/accounts/#{account.id}/conversations/#{conversation.display_id}", headers: administrator.create_new_auth_token

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body['applied_sla']['id']).to eq(applied_sla.id)
      expect(response.parsed_body['sla_events'].first['id']).to eq(sla_event.id)
    end

    it 'does not return SLA data for the conversation if the feature is disabled' do
      account.disable_features!('sla')
      conversation = create(:conversation, account: account)
      create(:applied_sla, conversation: conversation)
      create(:sla_event, conversation: conversation)

      get "/api/v1/accounts/#{account.id}/conversations/#{conversation.display_id}", headers: administrator.create_new_auth_token

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body.keys).not_to include('applied_sla')
      expect(response.parsed_body.keys).not_to include('sla_events')
    end

    context 'when agent has team access' do
      let(:agent) { create(:user, account: account, role: :agent) }
      let(:team) { create(:team, account: account) }
      let(:conversation) { create(:conversation, account: account, team: team) }

      before do
        create(:team_member, team: team, user: agent)
      end

      it 'allows accessing the conversation via team membership' do
        get "/api/v1/accounts/#{account.id}/conversations/#{conversation.display_id}", headers: agent.create_new_auth_token

        expect(response).to have_http_status(:ok)
        expect(response.parsed_body['id']).to eq(conversation.display_id)
      end
    end

    context 'when agent has a custom role' do
      let(:agent) { create(:user, account: account, role: :agent) }
      let(:conversation) { create(:conversation, account: account) }

      before do
        create(:inbox_member, user: agent, inbox: conversation.inbox)
      end

      it 'returns unauthorized for unassigned conversation without permission' do
        custom_role = create(:custom_role, account: account, permissions: ['conversation_participating_manage'])
        account.account_users.find_by(user_id: agent.id).update!(custom_role: custom_role)

        get "/api/v1/accounts/#{account.id}/conversations/#{conversation.display_id}", headers: agent.create_new_auth_token

        expect(response).to have_http_status(:unauthorized)
      end

      it 'returns the conversation when permission allows managing unassigned conversations, including when assigned to agent' do
        custom_role = create(:custom_role, account: account, permissions: ['conversation_unassigned_manage'])
        account_user = account.account_users.find_by(user_id: agent.id)
        account_user.update!(custom_role: custom_role)
        conversation.update!(assignee: agent)

        get "/api/v1/accounts/#{account.id}/conversations/#{conversation.display_id}", headers: agent.create_new_auth_token

        expect(response).to have_http_status(:ok)
        expect(response.parsed_body['id']).to eq(conversation.display_id)
      end

      it 'returns the conversation when permission allows managing assigned conversations' do
        custom_role = create(:custom_role, account: account, permissions: ['conversation_participating_manage'])
        account_user = account.account_users.find_by(user_id: agent.id)
        account_user.update!(custom_role: custom_role)
        conversation.update!(assignee: agent)

        get "/api/v1/accounts/#{account.id}/conversations/#{conversation.display_id}", headers: agent.create_new_auth_token

        expect(response).to have_http_status(:ok)
        expect(response.parsed_body['id']).to eq(conversation.display_id)
      end

      it 'returns the conversation when permission allows managing participating conversations' do
        custom_role = create(:custom_role, account: account, permissions: ['conversation_participating_manage'])
        account_user = account.account_users.find_by(user_id: agent.id)
        account_user.update!(custom_role: custom_role)
        create(:conversation_participant, conversation: conversation, account: account, user: agent)

        get "/api/v1/accounts/#{account.id}/conversations/#{conversation.display_id}", headers: agent.create_new_auth_token

        expect(response).to have_http_status(:ok)
        expect(response.parsed_body['id']).to eq(conversation.display_id)
      end
    end
  end
end
