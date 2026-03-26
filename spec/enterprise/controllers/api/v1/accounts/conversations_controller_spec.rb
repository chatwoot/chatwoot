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

  describe 'GET /api/v1/accounts/{account.id}/conversations/:id/reporting_events' do
    let(:conversation) { create(:conversation, account: account) }
    let(:inbox) { conversation.inbox }
    let(:agent) { administrator }

    before do
      # Create reporting events for this conversation
      @event1 = create(:reporting_event,
                       account: account,
                       conversation: conversation,
                       inbox: inbox,
                       user: agent,
                       name: 'first_response',
                       value: 120,
                       created_at: 3.hours.ago)

      @event2 = create(:reporting_event,
                       account: account,
                       conversation: conversation,
                       inbox: inbox,
                       user: agent,
                       name: 'reply_time',
                       value: 45,
                       created_at: 2.hours.ago)

      @event3 = create(:reporting_event,
                       account: account,
                       conversation: conversation,
                       inbox: inbox,
                       user: agent,
                       name: 'resolution',
                       value: 300,
                       created_at: 1.hour.ago)

      # Create an event for a different conversation (should not be included)
      other_conversation = create(:conversation, account: account)
      create(:reporting_event,
             account: account,
             conversation: other_conversation,
             inbox: other_conversation.inbox,
             user: agent,
             name: 'other_conversation_event',
             value: 60)
    end

    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get "/api/v1/accounts/#{account.id}/conversations/#{conversation.display_id}/reporting_events",
            as: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user with conversation access' do
      it 'returns all reporting events for the conversation' do
        get "/api/v1/accounts/#{account.id}/conversations/#{conversation.display_id}/reporting_events",
            headers: administrator.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        json_response = response.parsed_body

        # Should return array directly (no pagination)
        expect(json_response).to be_an(Array)
        expect(json_response.size).to eq(3)

        # Check they are sorted by created_at asc (oldest first)
        expect(json_response.first['name']).to eq('first_response')
        expect(json_response.last['name']).to eq('resolution')

        # Verify it doesn't include events from other conversations
        event_names = json_response.map { |e| e['name'] }
        expect(event_names).not_to include('other_conversation_event')
      end

      it 'returns empty array when conversation has no reporting events' do
        conversation_without_events = create(:conversation, account: account)

        get "/api/v1/accounts/#{account.id}/conversations/#{conversation_without_events.display_id}/reporting_events",
            headers: administrator.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        json_response = response.parsed_body

        expect(json_response).to be_an(Array)
        expect(json_response).to be_empty
      end
    end

    context 'when agent has limited access' do
      let(:limited_agent) { create(:user, account: account, role: :agent) }

      it 'returns unauthorized for unassigned conversation without permission' do
        get "/api/v1/accounts/#{account.id}/conversations/#{conversation.display_id}/reporting_events",
            headers: limited_agent.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:unauthorized)
      end

      it 'returns reporting events when agent is assigned to the conversation' do
        conversation.update!(assignee: limited_agent)
        # Also create inbox member for the agent
        create(:inbox_member, user: limited_agent, inbox: conversation.inbox)

        get "/api/v1/accounts/#{account.id}/conversations/#{conversation.display_id}/reporting_events",
            headers: limited_agent.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        json_response = response.parsed_body

        expect(json_response).to be_an(Array)
        expect(json_response.size).to eq(3)
      end
    end

    context 'when agent has team access' do
      let(:team_agent) { create(:user, account: account, role: :agent) }
      let(:team) { create(:team, account: account) }

      before do
        create(:team_member, team: team, user: team_agent)
        conversation.update!(team: team)
      end

      it 'allows accessing conversation reporting events via team membership' do
        get "/api/v1/accounts/#{account.id}/conversations/#{conversation.display_id}/reporting_events",
            headers: team_agent.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        json_response = response.parsed_body

        expect(json_response).to be_an(Array)
        expect(json_response.size).to eq(3)
      end
    end
  end
end
