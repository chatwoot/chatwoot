require 'rails_helper'

RSpec.describe 'Conversations API', type: :request do
  let(:account) { create(:account) }
  let(:administrator) { create(:user, account: account, role: :administrator) }

  describe 'POST /api/v1/accounts/{account.id}/conversations/filter with verified indexing' do
    include_context 'with conversation search queue'

    let(:conversation) { create(:conversation, account: account, status: :open) }
    let(:client) { instance_double(OpenSearch::Client) }

    before do
      allow(ChatwootApp).to receive(:advanced_search_allowed?).and_return(true)
      account.enable_features!('advanced_search_conversations')
      allow(SearchIndexing::IndexVerification).to receive(:ready?).and_return(true)
      allow(Searchkick).to receive(:client).and_return(client)
      allow(client).to receive(:search).and_return(
        '_shards' => { 'failed' => 0 },
        'hits' => { 'total' => { 'value' => 1, 'relation' => 'eq' }, 'hits' => [{ '_id' => conversation.id.to_s }] },
        'aggregations' => { 'mine' => { 'doc_count' => 0 }, 'unassigned' => { 'doc_count' => 1 } }
      )
    end

    it 'preserves the API payload and counts when indexed filtering is active' do
      post "/api/v1/accounts/#{account.id}/conversations/filter",
           headers: administrator.create_new_auth_token,
           params: { payload: [{ attribute_key: 'status', filter_operator: 'equal_to', values: ['open'] }] }, as: :json

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body['payload'].pluck('id')).to eq([conversation.display_id])
      expect(response.parsed_body['meta']).to include('all_count' => 1, 'unassigned_count' => 1)
      expect(client).to have_received(:search)
    end
  end

  describe 'GET /api/v1/accounts/{account.id}/conversations/:id' do
    it 'omits a missing Captain assistant owner' do
      conversation = create(:conversation, account: account)
      conversation.update!(ai_assignee_type: 'Captain::Assistant', assignee_agent_bot_id: -1)

      get "/api/v1/accounts/#{account.id}/conversations/#{conversation.display_id}", headers: administrator.create_new_auth_token

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body['meta'].keys).not_to include('assignee', 'assignee_type')
    end

    it 'returns SLA data for the conversation if the feature is enabled' do
      account.enable_features!('sla')
      conversation = create(:conversation, account: account)
      applied_sla = create(:applied_sla, conversation: conversation, completed_at: 1.hour.ago)
      sla_event = create(:sla_event, conversation: conversation, applied_sla: applied_sla)

      get "/api/v1/accounts/#{account.id}/conversations/#{conversation.display_id}", headers: administrator.create_new_auth_token

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body['applied_sla']['id']).to eq(applied_sla.id)
      expect(response.parsed_body['applied_sla']['sla_completed_at']).to eq(applied_sla.completed_at.to_i)
      expect(response.parsed_body['sla_events'].first['id']).to eq(sla_event.id)
    end

    it 'returns cleared SLA data when the contact is blocked' do
      account.enable_features!('sla')
      conversation = create(:conversation, account: account)
      applied_sla = create(:applied_sla, conversation: conversation)
      create(:sla_event, conversation: conversation, applied_sla: applied_sla)
      conversation.contact.update!(blocked: true)

      get "/api/v1/accounts/#{account.id}/conversations/#{conversation.display_id}", headers: administrator.create_new_auth_token

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body['sla_policy_id']).to be_nil
      expect(response.parsed_body['applied_sla']).to be_nil
      expect(response.parsed_body['sla_events']).to eq([])
    end

    it 'does not return SLA data for the conversation if the feature is disabled' do
      account.enable_features!('sla')
      sla_policy = create(:sla_policy, account: account)
      conversation = create(:conversation, account: account, sla_policy: sla_policy)
      create(:sla_event, conversation: conversation, applied_sla: conversation.applied_sla)
      account.disable_features!('sla')

      get "/api/v1/accounts/#{account.id}/conversations/#{conversation.display_id}", headers: administrator.create_new_auth_token

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body.keys).not_to include('applied_sla')
      expect(response.parsed_body.keys).not_to include('sla_events')
      expect(response.parsed_body['sla_policy_id']).to be_nil
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
