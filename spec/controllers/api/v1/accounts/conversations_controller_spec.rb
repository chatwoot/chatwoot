require 'rails_helper'

RSpec.describe 'Conversations API', type: :request do
  let(:account) { create(:account) }

  describe 'GET /api/v1/accounts/{account.id}/conversations' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get "/api/v1/accounts/#{account.id}/conversations"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      let(:agent) { create(:user, account: account, role: :agent) }
      let(:conversation) { create(:conversation, account: account) }

      before do
        create(:inbox_member, user: agent, inbox: conversation.inbox)
      end

      it 'returns all conversations with messages' do
        message = create(:message, conversation: conversation, account: account)
        get "/api/v1/accounts/#{account.id}/conversations",
            headers: agent.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        expect(response).to conform_schema(200)
        body = JSON.parse(response.body, symbolize_names: true)
        expect(body[:data][:meta][:all_count]).to eq(1)
        expect(body[:data][:meta].keys).to include(:all_count, :mine_count, :assigned_count, :unassigned_count)
        expect(body[:data][:payload].first[:uuid]).to eq(conversation.uuid)
        expect(body[:data][:payload].first[:messages].first[:id]).to eq(message.id)
      end

      # Regression (#781): there is no foreign key on assignee_id, so a user removed
      # without its callbacks leaves the id behind. One such row took the whole list
      # down with a 500; it renders as unassigned and the rest of the page with it.
      it 'lists a conversation whose assignee no longer exists as unassigned' do
        assigned = create(:conversation, account: account, inbox: conversation.inbox, assignee: agent)
        conversation.update_column(:assignee_id, User.maximum(:id) + 1000) # rubocop:disable Rails/SkipsModelValidations

        get "/api/v1/accounts/#{account.id}/conversations",
            headers: agent.create_new_auth_token,
            params: { assignee_type: 'all' },
            as: :json

        expect(response).to have_http_status(:success)
        payload = JSON.parse(response.body, symbolize_names: true)[:data][:payload].index_by { |item| item[:id] }
        expect(payload.keys).to contain_exactly(conversation.display_id, assigned.display_id)
        expect(payload[conversation.display_id][:meta]).not_to include(:assignee, :assignee_type)
        expect(payload[assigned.display_id][:meta][:assignee][:id]).to eq(agent.id)
        expect(payload[assigned.display_id][:meta][:assignee_type]).to eq('User')
      end

      # Regression: when the latest message is a private note, the seed is the
      # cursor for setActiveChat → fetchPreviousMessages(before: id). Filtering
      # private notes here would leave the trailing note out of the store on
      # cold open, so the bubble wouldn't render until a non-private message
      # arrived after it.
      it 'seeds the latest message even when it is a private note' do
        create(:message, conversation: conversation, account: account)
        private_note = create(:message, conversation: conversation, account: account, private: true)

        get "/api/v1/accounts/#{account.id}/conversations",
            headers: agent.create_new_auth_token,
            as: :json

        payload = JSON.parse(response.body, symbolize_names: true)[:data][:payload].first
        expect(payload[:messages].first[:id]).to eq(private_note.id)
        # The card preview shows private notes too — only activity messages are
        # filtered out of `last_non_activity_message`.
        expect(payload[:last_non_activity_message][:id]).to eq(private_note.id)
      end

      # Regression (#350): the seed is the `before` cursor and pages with
      # `id < before`, so filtering activity messages out of it hid every
      # status/assignment change created after the last regular message. The
      # card preview reads `last_non_activity_message`, which is a separate
      # query — do not collapse the two again.
      it 'seeds the latest message even when it is an activity message, without leaking it into the preview' do
        message = create(:message, conversation: conversation, account: account)
        activity = create(:message, conversation: conversation, account: account, message_type: :activity,
                                    content: 'Conversation was marked resolved by John')

        get "/api/v1/accounts/#{account.id}/conversations",
            headers: agent.create_new_auth_token,
            as: :json

        payload = JSON.parse(response.body, symbolize_names: true)[:data][:payload].first
        expect(payload[:messages].first[:id]).to eq(activity.id)
        expect(payload[:last_non_activity_message][:id]).to eq(message.id)
      end

      # Regression (#350): the seed and the message pagination have to line up.
      # This walks the exact path the dashboard takes on cold open — read the
      # seed from the list, then page with it as the `before` cursor.
      it 'reaches every activity message through the seed cursor' do
        create(:message, conversation: conversation, account: account)
        activity = create(:message, conversation: conversation, account: account, message_type: :activity,
                                    content: 'Conversation was marked resolved by John')

        get "/api/v1/accounts/#{account.id}/conversations",
            headers: agent.create_new_auth_token,
            as: :json
        seed = JSON.parse(response.body, symbolize_names: true)[:data][:payload].first[:messages]

        get "/api/v1/accounts/#{account.id}/conversations/#{conversation.display_id}/messages",
            params: { before: seed.first[:id] },
            headers: agent.create_new_auth_token,
            as: :json
        paginated = JSON.parse(response.body, symbolize_names: true)[:payload]

        expect(seed.pluck(:id) + paginated.pluck(:id)).to include(activity.id)
      end

      it 'lists a conversation whose contact no longer exists with an empty sender' do
        with_contact = create(:conversation, account: account, inbox: conversation.inbox)
        Contact.where(id: conversation.contact_id).delete_all

        get "/api/v1/accounts/#{account.id}/conversations",
            headers: agent.create_new_auth_token,
            params: { assignee_type: 'all' },
            as: :json

        expect(response).to have_http_status(:success)
        payload = JSON.parse(response.body, symbolize_names: true)[:data][:payload].index_by { |item| item[:id] }
        expect(payload.keys).to contain_exactly(conversation.display_id, with_contact.display_id)
        expect(payload[conversation.display_id][:meta][:sender]).to eq({})
        expect(payload[with_contact.display_id][:meta][:sender][:id]).to eq(with_contact.contact_id)
      end

      it 'returns conversations with empty messages array for conversations with out messages' do
        get "/api/v1/accounts/#{account.id}/conversations",
            headers: agent.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        body = JSON.parse(response.body, symbolize_names: true)
        expect(body[:data][:meta][:all_count]).to eq(1)
        expect(body[:data][:payload].first[:messages]).to eq([])
      end

      it 'returns unattended conversations' do
        attended_conversation = create(:conversation, account: account, first_reply_created_at: Time.now.utc)
        # to ensure that waiting since value is populated
        create(:message, message_type: :outgoing, conversation: attended_conversation, account: account)
        unattended_conversation_no_first_reply = create(:conversation, account: account, first_reply_created_at: nil)
        unattended_conversation_waiting_since = create(:conversation, account: account, first_reply_created_at: Time.now.utc)

        agent_1 = create(:user, account: account, role: :agent)
        create(:inbox_member, user: agent_1, inbox: attended_conversation.inbox)
        create(:inbox_member, user: agent_1, inbox: unattended_conversation_no_first_reply.inbox)
        create(:inbox_member, user: agent_1, inbox: unattended_conversation_waiting_since.inbox)

        get "/api/v1/accounts/#{account.id}/conversations",
            headers: agent_1.create_new_auth_token,
            params: { conversation_type: 'unattended' },
            as: :json

        expect(response).to have_http_status(:success)
        body = JSON.parse(response.body, symbolize_names: true)
        expect(body[:data][:meta][:all_count]).to eq(2)
        expect(body[:data][:payload].count).to eq(2)
      end
    end
  end

  describe 'GET /api/v1/accounts/{account.id}/conversations/meta' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get "/api/v1/accounts/#{account.id}/conversations/meta"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      let(:agent) { create(:user, account: account, role: :agent) }

      before do
        conversation = create(:conversation, account: account)
        create(:inbox_member, user: agent, inbox: conversation.inbox)
      end

      it 'returns all conversations counts' do
        get "/api/v1/accounts/#{account.id}/conversations/meta",
            headers: agent.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        body = JSON.parse(response.body, symbolize_names: true)
        expect(body[:meta].keys).to include(:all_count, :mine_count, :assigned_count, :unassigned_count)
        expect(body[:meta][:all_count]).to eq(1)
      end
    end
  end

  describe 'POST /api/v1/accounts/{account.id}/conversations/sync' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        post "/api/v1/accounts/#{account.id}/conversations/sync"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      let(:agent) { create(:user, account: account, role: :agent) }
      let(:inbox) { create(:inbox, account: account) }
      let!(:unassigned) { create(:conversation, account: account, inbox: inbox, assignee: nil) }

      before do
        create(:inbox_member, user: agent, inbox: inbox)
      end

      def sync(ids)
        post "/api/v1/accounts/#{account.id}/conversations/sync",
             headers: agent.create_new_auth_token,
             params: { ids: ids },
             as: :json
      end

      it 'returns the current state of the conversations it was asked about' do
        unassigned.update!(assignee: agent)
        sync([unassigned.display_id])

        expect(response).to have_http_status(:success)
        conversation = response.parsed_body['payload'].first
        expect(conversation['id']).to eq(unassigned.display_id)
        expect(conversation['meta']['assignee']['id']).to eq(agent.id)
      end

      # The rows worth asking about are the ones that stopped matching the tab, so answering only
      # about the ones that still match would say nothing about any of them.
      it 'ignores the tab filters entirely' do
        resolved = create(:conversation, account: account, inbox: inbox, assignee: nil, status: :resolved)
        assigned = create(:conversation, account: account, inbox: inbox, assignee: agent)
        group = create(:conversation, account: account, inbox: inbox, assignee: nil, group_type: :group)

        sync([resolved.display_id, assigned.display_id, group.display_id])

        expect(response.parsed_body['payload'].map { |c| c['id'] })
          .to contain_exactly(resolved.display_id, assigned.display_id, group.display_id)
      end

      it 'never answers about an id it was not given' do
        other = create(:conversation, account: account, inbox: inbox, assignee: nil)

        sync([unassigned.display_id])

        expect(response.parsed_body['payload'].map { |c| c['id'] }).to contain_exactly(unassigned.display_id)
        expect(response.parsed_body['payload'].map { |c| c['id'] }).not_to include(other.display_id)
      end

      it 'returns nothing when asked about nothing' do
        sync(nil)

        expect(response).to have_http_status(:success)
        expect(response.parsed_body['payload']).to be_empty
      end

      # What does not come back is what the caller drops, so a conversation in an inbox the agent
      # cannot reach has to be absent rather than merely filtered out of a later step.
      it 'leaves out conversations in inboxes the agent has no access to' do
        other_inbox_conversation = create(:conversation, account: account, assignee: nil)

        sync([unassigned.display_id, other_inbox_conversation.display_id])

        expect(response.parsed_body['payload'].map { |c| c['id'] }).to contain_exactly(unassigned.display_id)
      end

      # Refused, not truncated: a short answer is indistinguishable from "these conversations are
      # gone" to a caller that removes whatever does not come back.
      it 'refuses a batch larger than one page instead of answering partially' do
        sync((1..(Api::V1::Accounts::ConversationsController::SYNC_BATCH_SIZE + 1)).to_a)

        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'accepts a batch of exactly one page' do
        sync((1..Api::V1::Accounts::ConversationsController::SYNC_BATCH_SIZE).to_a)

        expect(response).to have_http_status(:success)
      end
    end
  end

  describe 'GET /api/v1/accounts/{account.id}/conversations/unread_counts' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get "/api/v1/accounts/#{account.id}/conversations/unread_counts"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      let(:agent) { create(:user, account: account, role: :agent) }
      let(:visible_inbox) { create(:inbox, account: account) }
      let(:hidden_inbox) { create(:inbox, account: account) }
      let(:label) { create(:label, account: account, title: 'billing', show_on_sidebar: true) }
      let(:team) { create(:team, account: account, allow_auto_assign: false) }

      before do
        create(:inbox_member, user: agent, inbox: visible_inbox)
        create(:team_member, user: agent, team: team)
      end

      after do
        Conversations::UnreadCounts::Store.clear_account!(account.id)
      end

      context 'when conversation unread counts feature is enabled' do
        before do
          account.enable_features!(:conversation_unread_counts)
        end

        it 'returns unread conversation counts scoped to the signed-in user' do
          create_unread_conversation(account: account, inbox: visible_inbox, labels: [label.title])
          create_unread_conversation(account: account, inbox: hidden_inbox, labels: [label.title])

          get "/api/v1/accounts/#{account.id}/conversations/unread_counts",
              headers: agent.create_new_auth_token,
              as: :json

          expect(response).to have_http_status(:success)
          expect(response.parsed_body['payload']).to eq(
            'all_count' => 1,
            'inboxes' => { visible_inbox.id.to_s => 1 },
            'labels' => { label.id.to_s => 1 },
            'teams' => {}
          )
        end

        it 'returns unread team conversation counts scoped to the signed-in user' do
          create_unread_conversation(account: account, inbox: visible_inbox, team: team)
          create_unread_conversation(account: account, inbox: hidden_inbox, team: team)

          get "/api/v1/accounts/#{account.id}/conversations/unread_counts",
              headers: agent.create_new_auth_token,
              as: :json

          expect(response).to have_http_status(:success)
          expect(response.parsed_body['payload']['teams']).to eq(team.id.to_s => 1)
        end

        it 'returns filtered unread counts when the filtered count feature is enabled' do
          account.enable_features!(:unread_count_for_filters)
          allow(Conversations::UnreadCounts::FilteredCountInstrumentation).to receive(:summarize_request) do |**_attributes, &block|
            block.call
          end
          mentioned = create_unread_conversation(account: account, inbox: visible_inbox)
          create(:mention, account: account, conversation: mentioned, user: agent)

          get "/api/v1/accounts/#{account.id}/conversations/unread_counts",
              headers: agent.create_new_auth_token,
              as: :json

          expect(response).to have_http_status(:success)
          expect(response.parsed_body['payload']).to include(
            'mentions_count' => 1,
            'participating_count' => 0,
            'unattended_count' => 1,
            'folders' => {}
          )
          expect(Conversations::UnreadCounts::FilteredCountInstrumentation).to have_received(:summarize_request).with(account_id: account.id)
        end
      end

      it 'returns forbidden when conversation unread counts feature is disabled' do
        get "/api/v1/accounts/#{account.id}/conversations/unread_counts",
            headers: agent.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:forbidden)
        expect(response.parsed_body['error']).to eq('Conversation unread counts feature not enabled for this account')
      end
    end
  end

  describe 'GET /api/v1/accounts/{account.id}/conversations/search' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get "/api/v1/accounts/#{account.id}/conversations/search", params: { q: 'test' }

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      let(:agent) { create(:user, account: account, role: :agent) }

      before do
        conversation = create(:conversation, account: account)
        create(:message, conversation: conversation, account: account, content: 'test1')
        create(:message, conversation: conversation, account: account, content: 'test2')
        create(:inbox_member, user: agent, inbox: conversation.inbox)
      end

      it 'returns all conversations with messages containing the search query' do
        get "/api/v1/accounts/#{account.id}/conversations/search",
            headers: agent.create_new_auth_token,
            params: { q: 'test1' },
            as: :json

        expect(response).to have_http_status(:success)
        response_data = JSON.parse(response.body, symbolize_names: true)
        expect(response_data[:meta][:all_count]).to eq(1)
        expect(response_data[:payload].first[:messages].first[:content]).to eq 'test1'
      end
    end
  end

  describe 'GET /api/v1/accounts/{account.id}/conversations/filter' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        post "/api/v1/accounts/#{account.id}/conversations/filter", params: { q: 'test' }

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      let(:agent) { create(:user, account: account, role: :agent) }

      before do
        conversation = create(:conversation, account: account)
        create(:message, conversation: conversation, account: account, content: 'test1')
        create(:message, conversation: conversation, account: account, content: 'test2')
        create(:inbox_member, user: agent, inbox: conversation.inbox)
      end

      it 'returns all conversations matching the query' do
        post "/api/v1/accounts/#{account.id}/conversations/filter",
             headers: agent.create_new_auth_token,
             params: {
               payload: [{
                 attribute_key: 'status',
                 filter_operator: 'equal_to',
                 values: ['open']
               }]
             },
             as: :json

        expect(response).to have_http_status(:success)
        expect(response).to conform_schema(200)
        response_data = JSON.parse(response.body, symbolize_names: true)
        expect(response_data.count).to eq(2)
      end

      it 'returns error if the filters contain invalid attributes' do
        post "/api/v1/accounts/#{account.id}/conversations/filter",
             headers: agent.create_new_auth_token,
             params: {
               payload: [{
                 attribute_key: 'phone_number',
                 filter_operator: 'equal_to',
                 values: ['open']
               }]
             },
             as: :json

        expect(response).to have_http_status(:unprocessable_entity)
        response_data = JSON.parse(response.body, symbolize_names: true)
        expect(response_data[:error]).to include('Invalid attribute key - [phone_number]')
      end

      it 'returns error if the filters contain invalid operator' do
        post "/api/v1/accounts/#{account.id}/conversations/filter",
             headers: agent.create_new_auth_token,
             params: {
               payload: [{
                 attribute_key: 'status',
                 filter_operator: 'eq',
                 values: ['open']
               }]
             },
             as: :json

        expect(response).to have_http_status(:unprocessable_entity)
        response_data = JSON.parse(response.body, symbolize_names: true)
        expect(response_data[:error]).to eq('Invalid operator. The allowed operators for status are [equal_to,not_equal_to].')
      end
    end
  end

  describe 'GET /api/v1/accounts/{account.id}/conversations/:id' do
    let(:conversation) { create(:conversation, account: account) }

    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get "/api/v1/accounts/#{account.id}/conversations/#{conversation.display_id}"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      let(:agent) { create(:user, account: account, role: :agent) }
      let(:administrator) { create(:user, account: account, role: :administrator) }

      it 'does not shows the conversation if you do not have access to it' do
        get "/api/v1/accounts/#{account.id}/conversations/#{conversation.display_id}",
            headers: agent.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:unauthorized)
      end

      it 'shows the conversation if you are an administrator' do
        get "/api/v1/accounts/#{account.id}/conversations/#{conversation.display_id}",
            headers: administrator.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        expect(response).to conform_schema(200)
        expect(JSON.parse(response.body, symbolize_names: true)[:id]).to eq(conversation.display_id)
      end

      it 'shows the conversation if you are an agent with access to inbox' do
        create(:inbox_member, user: agent, inbox: conversation.inbox)
        get "/api/v1/accounts/#{account.id}/conversations/#{conversation.display_id}",
            headers: agent.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        expect(JSON.parse(response.body, symbolize_names: true)[:id]).to eq(conversation.display_id)
      end
    end

    context 'when it is an authenticated bot' do
      let(:agent_bot) { create(:agent_bot, account: account) }
      let(:team) { create(:team, account: account) }

      it 'shows a team-assigned conversation' do
        conversation.update!(team: team)

        get "/api/v1/accounts/#{account.id}/conversations/#{conversation.display_id}",
            headers: { api_access_token: agent_bot.access_token.token },
            as: :json

        expect(response).to have_http_status(:success)
        expect(response.parsed_body.dig('meta', 'team', 'is_member')).to be(false)
      end
    end
  end

  describe 'PATCH /api/v1/accounts/{account.id}/conversations/:id' do
    let(:conversation) { create(:conversation, account: account) }
    let(:params) { { priority: 'high' } }

    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        patch "/api/v1/accounts/#{account.id}/conversations/#{conversation.display_id}",
              params: params

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      let(:agent) { create(:user, account: account, role: :agent) }
      let(:administrator) { create(:user, account: account, role: :administrator) }

      it 'does not update the conversation if you do not have access to it' do
        patch "/api/v1/accounts/#{account.id}/conversations/#{conversation.display_id}",
              params: params,
              headers: agent.create_new_auth_token,
              as: :json

        expect(response).to have_http_status(:unauthorized)
      end

      it 'updates the conversation if you are an administrator' do
        patch "/api/v1/accounts/#{account.id}/conversations/#{conversation.display_id}",
              params: params,
              headers: administrator.create_new_auth_token,
              as: :json

        expect(response).to have_http_status(:success)
        expect(response).to conform_schema(200)
        expect(JSON.parse(response.body, symbolize_names: true)[:priority]).to eq('high')
      end

      it 'updates the conversation if you are an agent with access to inbox' do
        create(:inbox_member, user: agent, inbox: conversation.inbox)
        patch "/api/v1/accounts/#{account.id}/conversations/#{conversation.display_id}",
              params: params,
              headers: agent.create_new_auth_token,
              as: :json

        expect(response).to have_http_status(:success)
        expect(JSON.parse(response.body, symbolize_names: true)[:priority]).to eq('high')
      end
    end
  end

  describe 'POST /api/v1/accounts/{account.id}/conversations' do
    let(:contact) { create(:contact, account: account) }
    let(:inbox) { create(:inbox, account: account) }
    let!(:contact_inbox) { create(:contact_inbox, contact: contact, inbox: inbox) }

    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        post "/api/v1/accounts/#{account.id}/conversations",
             params: { source_id: contact_inbox.source_id },
             as: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      let(:agent) { create(:user, account: account, role: :agent, auto_offline: false) }
      let(:team) { create(:team, account: account) }

      it 'will not create a new conversation if agent does not have access to inbox' do
        allow(Rails.configuration.dispatcher).to receive(:dispatch)
        additional_attributes = { test: 'test' }
        post "/api/v1/accounts/#{account.id}/conversations",
             headers: agent.create_new_auth_token,
             params: { source_id: contact_inbox.source_id, additional_attributes: additional_attributes },
             as: :json
        expect(response).to have_http_status(:unauthorized)
      end

      context 'when it is an authenticated user who has access to the inbox' do
        before do
          create(:inbox_member, user: agent, inbox: inbox)
          create(:team_member, user: agent, team: team)
        end

        it 'creates a new conversation' do
          allow(Rails.configuration.dispatcher).to receive(:dispatch)
          additional_attributes = { test: 'test' }
          post "/api/v1/accounts/#{account.id}/conversations",
               headers: agent.create_new_auth_token,
               params: { source_id: contact_inbox.source_id, additional_attributes: additional_attributes },
               as: :json

          expect(response).to have_http_status(:success)
          expect(response).to conform_schema(200)
          response_data = JSON.parse(response.body, symbolize_names: true)
          expect(response_data[:additional_attributes]).to eq(additional_attributes)
        end

        it 'does not create a new conversation if source_id is not unique' do
          new_contact = create(:contact, account: account)

          post "/api/v1/accounts/#{account.id}/conversations",
               headers: agent.create_new_auth_token,
               params: { source_id: contact_inbox.source_id, inbox_id: inbox.id, contact_id: new_contact.id },
               as: :json
          expect(response).to have_http_status(:unprocessable_entity)
        end

        it 'creates a conversation in specificed status' do
          allow(Rails.configuration.dispatcher).to receive(:dispatch)
          post "/api/v1/accounts/#{account.id}/conversations",
               headers: agent.create_new_auth_token,
               params: { source_id: contact_inbox.source_id, status: 'pending' },
               as: :json

          expect(response).to have_http_status(:success)
          response_data = JSON.parse(response.body, symbolize_names: true)
          expect(response_data[:status]).to eq('pending')
        end

        it 'creates a new conversation with message when message is passed' do
          allow(Rails.configuration.dispatcher).to receive(:dispatch)
          post "/api/v1/accounts/#{account.id}/conversations",
               headers: agent.create_new_auth_token,
               params: { source_id: contact_inbox.source_id, message: { content: 'hi' } },
               as: :json

          expect(response).to have_http_status(:success)
          response_data = JSON.parse(response.body, symbolize_names: true)
          expect(response_data[:additional_attributes]).to eq({})
          expect(account.conversations.find_by(display_id: response_data[:id]).messages.outgoing.first.content).to eq 'hi'
        end

        it 'calls contact inbox builder if contact_id and inbox_id is present' do
          builder = double
          allow(Rails.configuration.dispatcher).to receive(:dispatch)
          allow(ContactInboxBuilder).to receive(:new)
            .with(contact: contact, inbox: inbox, source_id: nil, hmac_verified: false, validate_whatsapp_phone: true).and_return(builder)
          allow(builder).to receive(:perform)
          expect(builder).to receive(:perform)

          post "/api/v1/accounts/#{account.id}/conversations",
               headers: agent.create_new_auth_token,
               params: { contact_id: contact.id, inbox_id: inbox.id, hmac_verified: 'false' },
               as: :json
        end

        it 'does not trust client supplied hmac_verified param when creating the contact inbox' do
          allow(Rails.configuration.dispatcher).to receive(:dispatch)
          identified_contact = create(:contact, account: account, identifier: 'contact-identifier')

          post "/api/v1/accounts/#{account.id}/conversations",
               headers: agent.create_new_auth_token,
               params: { contact_id: identified_contact.id, inbox_id: inbox.id, hmac_verified: true },
               as: :json

          expect(response).to have_http_status(:success)
          conversation = account.conversations.find_by(display_id: JSON.parse(response.body, symbolize_names: true)[:id])
          expect(conversation.contact_inbox.hmac_verified).to be(false)
        end

        it 'marks the contact inbox hmac verified with a valid identifier hash' do
          allow(Rails.configuration.dispatcher).to receive(:dispatch)
          identified_contact = create(:contact, account: account, identifier: 'contact-identifier')
          identifier_hash = OpenSSL::HMAC.hexdigest('sha256', inbox.channel.hmac_token, identified_contact.identifier)

          post "/api/v1/accounts/#{account.id}/conversations",
               headers: agent.create_new_auth_token,
               params: { contact_id: identified_contact.id, inbox_id: inbox.id, identifier: identified_contact.identifier,
                         identifier_hash: identifier_hash },
               as: :json

          expect(response).to have_http_status(:success)
          conversation = account.conversations.find_by(display_id: JSON.parse(response.body, symbolize_names: true)[:id])
          expect(conversation.contact_inbox.hmac_verified).to be(true)
        end

        it 'creates a new conversation with assignee and team' do
          allow(Rails.configuration.dispatcher).to receive(:dispatch)
          post "/api/v1/accounts/#{account.id}/conversations",
               headers: agent.create_new_auth_token,
               params: { source_id: contact_inbox.source_id, contact_id: contact.id, inbox_id: inbox.id, assignee_id: agent.id, team_id: team.id },
               as: :json

          expect(response).to have_http_status(:success)
          response_data = JSON.parse(response.body, symbolize_names: true)
          expect(response_data[:meta][:assignee][:name]).to eq(agent.name)
          expect(response_data[:meta][:team][:name]).to eq(team.name)
        end

        it 'does not create a conversation with an assignee from another account' do
          other_user = create(:user, account: create(:account))

          expect do
            post "/api/v1/accounts/#{account.id}/conversations",
                 headers: agent.create_new_auth_token,
                 params: { source_id: contact_inbox.source_id, assignee_id: other_user.id },
                 as: :json
          end.not_to change(Conversation, :count)

          expect(response).to have_http_status(:unprocessable_entity)
        end

        it 'does not create a conversation with a team from another account' do
          other_team = create(:team, account: create(:account))

          expect do
            post "/api/v1/accounts/#{account.id}/conversations",
                 headers: agent.create_new_auth_token,
                 params: { source_id: contact_inbox.source_id, team_id: other_team.id },
                 as: :json
          end.not_to change(Conversation, :count)

          expect(response).to have_http_status(:unprocessable_entity)
        end
      end
    end

    context 'when it is an authenticated bot' do
      let(:bot) { create(:agent_bot, account: account) }
      let(:other_account) { create(:account) }
      let(:other_inbox) { create(:inbox, account: other_account) }
      let(:other_contact) { create(:contact, account: other_account) }
      let!(:other_contact_inbox) do
        create(:contact_inbox, contact: other_contact, inbox: other_inbox)
      end

      before { allow(Rails.configuration.dispatcher).to receive(:dispatch) }

      it 'does not create a conversation in another account from its source_id' do
        expect do
          post "/api/v1/accounts/#{account.id}/conversations",
               headers: { api_access_token: bot.access_token.token },
               params: { source_id: other_contact_inbox.source_id, message: { content: 'hi' } },
               as: :json
        end.not_to change(other_account.conversations, :count)

        expect(response).to have_http_status(:not_found)
      end

      it 'creates a conversation for a source_id in its own account' do
        expect do
          post "/api/v1/accounts/#{account.id}/conversations",
               headers: { api_access_token: bot.access_token.token },
               params: { source_id: contact_inbox.source_id },
               as: :json
        end.to change(account.conversations, :count).by(1)

        expect(response).to have_http_status(:success)
      end
    end
  end

  describe 'POST /api/v1/accounts/{account.id}/conversations/:id/toggle_status' do
    let(:conversation) { create(:conversation, account: account) }
    let(:inbox) { create(:inbox, account: account) }
    let(:pending_conversation) { create(:conversation, inbox: inbox, account: account, status: 'pending') }
    let(:agent_bot) { create(:agent_bot, account: account) }

    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        post "/api/v1/accounts/#{account.id}/conversations/#{conversation.display_id}/toggle_status"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      let(:agent) { create(:user, account: account, role: :agent) }
      let(:administrator) { create(:user, account: account, role: :administrator) }

      before do
        create(:inbox_member, user: agent, inbox: conversation.inbox)
      end

      it 'toggles the conversation status if status is empty' do
        expect(conversation.status).to eq('open')

        post "/api/v1/accounts/#{account.id}/conversations/#{conversation.display_id}/toggle_status",
             headers: agent.create_new_auth_token,
             params: { status: '' },
             as: :json

        expect(response).to have_http_status(:success)
        expect(conversation.reload.status).to eq('resolved')
      end

      it 'toggles the conversation status to open from pending' do
        conversation.update!(status: 'pending')

        post "/api/v1/accounts/#{account.id}/conversations/#{conversation.display_id}/toggle_status",
             headers: agent.create_new_auth_token,
             params: { status: 'open' },
             as: :json

        expect(response).to have_http_status(:success)
        expect(response).to conform_schema(200)
        expect(conversation.reload.status).to eq('open')
      end

      it 'self assign if agent changes the conversation status to open' do
        conversation.update!(status: 'pending')
        post "/api/v1/accounts/#{account.id}/conversations/#{conversation.display_id}/toggle_status",
             headers: agent.create_new_auth_token,
             as: :json
        expect(response).to have_http_status(:success)
        expect(conversation.reload.status).to eq('open')
        expect(conversation.reload.assignee_id).to eq(agent.id)
      end

      it 'does not self assign and clears the agent bot owner if admin changes the conversation status to open' do
        conversation.update!(status: 'pending', assignee: nil, ai_assignee: agent_bot)

        post "/api/v1/accounts/#{account.id}/conversations/#{conversation.display_id}/toggle_status",
             headers: administrator.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:success)
        expect(conversation.reload.status).to eq('open')
        expect(conversation.reload.assignee_id).not_to eq(administrator.id)
        expect(conversation.reload.ai_assignee).to be_nil
      end

      it 'toggles the conversation status to specific status when parameter is passed' do
        expect(conversation.status).to eq('open')

        post "/api/v1/accounts/#{account.id}/conversations/#{conversation.display_id}/toggle_status",
             headers: agent.create_new_auth_token,
             params: { status: 'pending' },
             as: :json

        expect(response).to have_http_status(:success)
        expect(conversation.reload.status).to eq('pending')
      end

      it 'toggles the conversation status to snoozed when parameter is passed' do
        expect(conversation.status).to eq('open')
        snoozed_until = (DateTime.now.utc + 2.days).to_i
        post "/api/v1/accounts/#{account.id}/conversations/#{conversation.display_id}/toggle_status",
             headers: agent.create_new_auth_token,
             params: { status: 'snoozed', snoozed_until: snoozed_until },
             as: :json

        expect(response).to have_http_status(:success)
        expect(conversation.reload.status).to eq('snoozed')
        expect(conversation.reload.snoozed_until.to_i).to eq(snoozed_until)
      end

      # Reopening self-assigns via `handle_human_open`, which is a second claim
      # path that bypasses Conversations::AssignmentService entirely.
      it 'answers 409 when reopening a conversation assigned to another agent' do
        owner = create(:user, account: account, role: :agent)
        create(:inbox_member, inbox: conversation.inbox, user: owner)
        conversation.update!(status: 'resolved', assignee: owner)
        conversation.inbox.update!(prevent_assignment_takeover: true)

        post "/api/v1/accounts/#{account.id}/conversations/#{conversation.display_id}/toggle_status",
             headers: agent.create_new_auth_token,
             params: { status: 'open' },
             as: :json

        expect(response).to have_http_status(:conflict)
        expect(response.parsed_body['agent_name']).to eq(owner.available_name)
        expect(conversation.reload.assignee).to eq(owner)
        # The status change and the self-assignment are separate saves; a refused
        # request must not leave the conversation reopened behind the 409.
        expect(conversation.reload.status).to eq('resolved')
      end

      # Opening a bot conversation self-assigns the agent, which is a claim.
      it 'answers 409 when opening a bot conversation while the inbox is closed' do
        conversation.update!(status: 'pending', assignee: nil)
        conversation.inbox.update!(working_hours_enabled: true, restrict_assignment_to_working_hours: true)

        travel_to(Time.utc(2026, 11, 8, 12)) do
          post "/api/v1/accounts/#{account.id}/conversations/#{conversation.display_id}/toggle_status",
               headers: agent.create_new_auth_token,
               params: { status: 'open' },
               as: :json
        end

        expect(response).to have_http_status(:conflict)
        expect(response.parsed_body['reason']).to eq('outside_working_hours')
        expect(conversation.reload.assignee).to be_nil
        expect(conversation.status).to eq('pending')
      end

      # Regression: reopening self-assigns the agent, and that used to be a
      # second save. `previous_changes` only carries the last save, so the
      # status callbacks (reopen activity message, automations, reporting) went
      # silent. Both changes have to land in one save.
      it 'still reports the status change when reopening self-assigns the agent' do
        conversation.update!(status: 'resolved', assignee: nil)
        # Stubbed after the setup, which is itself a status change.
        allow(Rails.configuration.dispatcher).to receive(:dispatch)

        post "/api/v1/accounts/#{account.id}/conversations/#{conversation.display_id}/toggle_status",
             headers: agent.create_new_auth_token,
             params: { status: 'open' },
             as: :json

        expect(response).to have_http_status(:success)
        expect(conversation.reload.assignee).to eq(agent)
        expect(Rails.configuration.dispatcher).to have_received(:dispatch)
          .with(Events::Types::CONVERSATION_STATUS_CHANGED, kind_of(Time), hash_including(conversation: conversation))
        expect(Rails.configuration.dispatcher).to have_received(:dispatch)
          .with(Events::Types::CONVERSATION_OPENED, kind_of(Time), hash_including(conversation: conversation))
      end
    end

    context 'when it is an authenticated bot' do
      # this test will basically ensure that the status actually changes
      # regardless of the value to be done
      it 'returns authorized for arbritrary status' do
        create(:agent_bot_inbox, inbox: inbox, agent_bot: agent_bot)

        conversation.update!(status: 'open')
        expect(conversation.reload.status).to eq('open')
        snoozed_until = (DateTime.now.utc + 2.days).to_i

        post "/api/v1/accounts/#{account.id}/conversations/#{conversation.display_id}/toggle_status",
             headers: { api_access_token: agent_bot.access_token.token },
             params: { status: 'snoozed', snoozed_until: snoozed_until },
             as: :json

        expect(response).to have_http_status(:success)
        expect(conversation.reload.status).to eq('snoozed')
      end

      it 'triggers handoff event when moving from pending to open' do
        create(:agent_bot_inbox, inbox: inbox, agent_bot: agent_bot)
        allow(Rails.configuration.dispatcher).to receive(:dispatch)

        post "/api/v1/accounts/#{account.id}/conversations/#{pending_conversation.display_id}/toggle_status",
             headers: { api_access_token: agent_bot.access_token.token },
             params: { status: 'open' },
             as: :json

        expect(response).to have_http_status(:success)
        expect(pending_conversation.reload.status).to eq('open')
        expect(Rails.configuration.dispatcher).to have_received(:dispatch)
          .with(Events::Types::CONVERSATION_BOT_HANDOFF, kind_of(Time), conversation: pending_conversation, notifiable_assignee_change: false,
                                                                        changed_attributes: anything, performed_by: anything)
      end

      it 'hands off a pending conversation when expected_status matches' do
        create(:agent_bot_inbox, inbox: inbox, agent_bot: agent_bot)
        allow(Rails.configuration.dispatcher).to receive(:dispatch)

        post "/api/v1/accounts/#{account.id}/conversations/#{pending_conversation.display_id}/toggle_status",
             headers: { api_access_token: agent_bot.access_token.token },
             params: { status: 'open', expected_status: 'pending' },
             as: :json

        expect(response).to have_http_status(:success)
        expect(pending_conversation.reload.status).to eq('open')
        expect(Rails.configuration.dispatcher).to have_received(:dispatch)
          .with(Events::Types::CONVERSATION_BOT_HANDOFF, kind_of(Time), hash_including(conversation: pending_conversation))
      end

      it 'leaves a conversation resolved meanwhile untouched and answers 409' do
        create(:agent_bot_inbox, inbox: inbox, agent_bot: agent_bot)
        pending_conversation.update!(status: 'resolved')

        post "/api/v1/accounts/#{account.id}/conversations/#{pending_conversation.display_id}/toggle_status",
             headers: { api_access_token: agent_bot.access_token.token },
             params: { status: 'open', expected_status: 'pending' },
             as: :json

        expect(response).to have_http_status(:conflict)
        expect(response.parsed_body['current_status']).to eq('resolved')
        expect(pending_conversation.reload.status).to eq('resolved')
      end

      it 'answers 409 when the conversation is resolved after the request loaded it' do
        create(:agent_bot_inbox, inbox: inbox, agent_bot: agent_bot)
        # An agent's resolve committing between the request loading the conversation and the bot's toggle.
        allow_any_instance_of(Api::V1::Accounts::ConversationsController) # rubocop:disable RSpec/AnyInstance
          .to receive(:toggle_status_if_expected).and_wrap_original do |original|
            Conversation.find(pending_conversation.id).update!(status: :resolved)
            original.call
          end

        post "/api/v1/accounts/#{account.id}/conversations/#{pending_conversation.display_id}/toggle_status",
             headers: { api_access_token: agent_bot.access_token.token },
             params: { status: 'open', expected_status: 'pending' },
             as: :json

        expect(response).to have_http_status(:conflict)
        expect(pending_conversation.reload.status).to eq('resolved')
      end

      it 'refuses an expected_status that is not a conversation status' do
        create(:agent_bot_inbox, inbox: inbox, agent_bot: agent_bot)

        post "/api/v1/accounts/#{account.id}/conversations/#{pending_conversation.display_id}/toggle_status",
             headers: { api_access_token: agent_bot.access_token.token },
             params: { status: 'open', expected_status: 'closed' },
             as: :json

        expect(response).to have_http_status(:unprocessable_entity)
        expect(pending_conversation.reload.status).to eq('pending')
      end

      it 'refuses a blank expected_status instead of toggling unconditionally' do
        create(:agent_bot_inbox, inbox: inbox, agent_bot: agent_bot)
        pending_conversation.update!(status: 'resolved')

        post "/api/v1/accounts/#{account.id}/conversations/#{pending_conversation.display_id}/toggle_status",
             headers: { api_access_token: agent_bot.access_token.token },
             params: { status: 'open', expected_status: '' },
             as: :json

        expect(response).to have_http_status(:unprocessable_entity)
        expect(pending_conversation.reload.status).to eq('resolved')
      end
    end
  end

  describe 'POST /api/v1/accounts/{account.id}/conversations/:id/toggle_priority' do
    let(:inbox) { create(:inbox, account: account) }
    let(:conversation) { create(:conversation, account: account) }
    let(:pending_conversation) { create(:conversation, inbox: inbox, account: account, status: 'pending') }
    let(:agent) { create(:user, account: account, role: :agent) }
    let(:agent_bot) { create(:agent_bot, account: account) }

    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        post "/api/v1/accounts/#{account.id}/conversations/#{conversation.display_id}/toggle_priority"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      let(:administrator) { create(:user, account: account, role: :administrator) }

      before do
        create(:inbox_member, user: agent, inbox: conversation.inbox)
      end

      it 'updates the conversation priority' do
        expect(conversation.priority).to be_nil

        post "/api/v1/accounts/#{account.id}/conversations/#{conversation.display_id}/toggle_priority",
             headers: agent.create_new_auth_token,
             params: { priority: 'low' },
             as: :json

        expect(response).to have_http_status(:success)
        expect(conversation.reload.priority).to eq('low')
      end

      it 'clears the conversation priority when priority is missing' do
        conversation.update!(priority: 'low')

        post "/api/v1/accounts/#{account.id}/conversations/#{conversation.display_id}/toggle_priority",
             headers: agent.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:success)
        expect(conversation.reload.priority).to be_nil
      end

      it 'clears the conversation priority when priority is nil' do
        conversation.priority = 'low'
        conversation.save!
        expect(conversation.reload.priority).to eq('low')

        post "/api/v1/accounts/#{account.id}/conversations/#{conversation.display_id}/toggle_priority",
             headers: agent.create_new_auth_token,
             params: { priority: nil },
             as: :json

        expect(response).to have_http_status(:success)
        expect(conversation.reload.priority).to be_nil
      end

      it 'returns unprocessable entity for invalid priority values' do
        ['none', '', false].each do |invalid_priority|
          post "/api/v1/accounts/#{account.id}/conversations/#{conversation.display_id}/toggle_priority",
               headers: agent.create_new_auth_token,
               params: { priority: invalid_priority },
               as: :json

          expect(response).to have_http_status(:unprocessable_entity)
          expect(response.parsed_body['error']).to include('priority')
        end
      end
    end

    context 'when it is an authenticated bot' do
      it 'toggle the priority of the bot agent conversation' do
        create(:agent_bot_inbox, inbox: inbox, agent_bot: agent_bot)

        conversation.update!(priority: 'low')
        expect(conversation.reload.priority).to eq('low')

        post "/api/v1/accounts/#{account.id}/conversations/#{conversation.display_id}/toggle_priority",
             headers: { api_access_token: agent_bot.access_token.token },
             params: { priority: 'high' },
             as: :json

        expect(response).to have_http_status(:success)
        expect(conversation.reload.priority).to eq('high')
      end
    end
  end

  describe 'POST /api/v1/accounts/{account.id}/conversations/:id/toggle_typing_status' do
    let(:conversation) { create(:conversation, account: account) }

    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        post "/api/v1/accounts/#{account.id}/conversations/#{conversation.display_id}/toggle_typing_status"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      let(:agent) { create(:user, account: account, role: :agent) }

      before do
        create(:inbox_member, user: agent, inbox: conversation.inbox)
      end

      it 'toggles the conversation status' do
        allow(Rails.configuration.dispatcher).to receive(:dispatch)
        post "/api/v1/accounts/#{account.id}/conversations/#{conversation.display_id}/toggle_typing_status",
             headers: agent.create_new_auth_token,
             params: { typing_status: 'on', is_private: false },
             as: :json

        expect(response).to have_http_status(:success)
        expect(Rails.configuration.dispatcher).to have_received(:dispatch)
          .with(Conversation::CONVERSATION_TYPING_ON, kind_of(Time), { conversation: conversation, user: agent, is_private: false })
      end

      it 'toggles the conversation status for private notes' do
        allow(Rails.configuration.dispatcher).to receive(:dispatch)
        post "/api/v1/accounts/#{account.id}/conversations/#{conversation.display_id}/toggle_typing_status",
             headers: agent.create_new_auth_token,
             params: { typing_status: 'on', is_private: true },
             as: :json

        expect(response).to have_http_status(:success)
        expect(Rails.configuration.dispatcher).to have_received(:dispatch)
          .with(Conversation::CONVERSATION_TYPING_ON, kind_of(Time), { conversation: conversation, user: agent, is_private: true })
      end
    end

    context 'when it is an authenticated bot' do
      let(:agent_bot) { create(:agent_bot, account: account) }

      it 'toggles the conversation typing status' do
        create(:agent_bot_inbox, inbox: conversation.inbox, agent_bot: agent_bot)
        allow(Rails.configuration.dispatcher).to receive(:dispatch)

        post "/api/v1/accounts/#{account.id}/conversations/#{conversation.display_id}/toggle_typing_status",
             headers: { api_access_token: agent_bot.access_token.token },
             params: { typing_status: 'on', is_private: false },
             as: :json

        expect(response).to have_http_status(:success)
        expect(Rails.configuration.dispatcher).to have_received(:dispatch)
          .with(Conversation::CONVERSATION_TYPING_ON, kind_of(Time), { conversation: conversation, user: agent_bot, is_private: false })
      end
    end

    context 'when it is an authenticated platform app token' do
      let(:platform_app) { create(:platform_app) }

      it 'returns unauthorized' do
        post "/api/v1/accounts/#{account.id}/conversations/#{conversation.display_id}/toggle_typing_status",
             headers: { api_access_token: platform_app.access_token.token },
             params: { typing_status: 'on', is_private: false },
             as: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe 'POST /api/v1/accounts/{account.id}/conversations/:id/update_last_seen' do
    let(:conversation) { create(:conversation, account: account) }

    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        post "/api/v1/accounts/#{account.id}/conversations/#{conversation.display_id}/update_last_seen"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      let(:agent) { create(:user, account: account, role: :agent) }

      before do
        create(:inbox_member, user: agent, inbox: conversation.inbox)
      end

      it 'updates last seen' do
        conversation.update!(agent_last_seen_at: nil)

        post "/api/v1/accounts/#{account.id}/conversations/#{conversation.display_id}/update_last_seen",
             headers: agent.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:success)
        expect(conversation.reload.agent_last_seen_at).not_to be_nil
      end

      it 'updates assignee last seen' do
        conversation.update!(assignee_id: agent.id, agent_last_seen_at: nil)

        expect(conversation.reload.assignee_last_seen_at).to be_nil

        post "/api/v1/accounts/#{account.id}/conversations/#{conversation.display_id}/update_last_seen",
             headers: agent.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:success)
        expect(conversation.reload.assignee_last_seen_at).not_to be_nil
      end

      it 'marks unread notifications as read when updating last seen' do
        allow(Rails.configuration.dispatcher).to receive(:dispatch)
        notification = create(:notification, account: account, user: agent, primary_actor: conversation, read_at: nil)

        post "/api/v1/accounts/#{account.id}/conversations/#{conversation.display_id}/update_last_seen",
             headers: agent.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:success)
        expect(notification.reload.read_at).to be_present
        expect(Rails.configuration.dispatcher).to have_received(:dispatch).with(
          'notification.updated',
          kind_of(Time),
          hash_including(notification: have_attributes(id: notification.id))
        )
      end

      it 'throttles updates within an hour when there are no unread messages' do
        conversation.update!(agent_last_seen_at: 30.minutes.ago, last_activity_at: 31.minutes.ago)
        # Ensure all messages are older than agent_last_seen_at (no unread messages)
        # rubocop:disable Rails/SkipsModelValidations
        conversation.messages.update_all(created_at: 1.hour.ago)
        # rubocop:enable Rails/SkipsModelValidations
        initial_last_seen = conversation.agent_last_seen_at

        post "/api/v1/accounts/#{account.id}/conversations/#{conversation.display_id}/update_last_seen",
             headers: agent.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:success)
        expect(conversation.reload.agent_last_seen_at).to be_within(1.second).of(initial_last_seen)
      end

      it 'updates even within an hour when there are unread messages' do
        conversation.update!(agent_last_seen_at: 30.minutes.ago)
        # Create a new message after agent_last_seen_at (unread message)
        create(:message, conversation: conversation, created_at: 5.minutes.ago)
        initial_last_seen = conversation.agent_last_seen_at

        post "/api/v1/accounts/#{account.id}/conversations/#{conversation.display_id}/update_last_seen",
             headers: agent.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:success)
        expect(conversation.reload.agent_last_seen_at).not_to be_within(1.second).of(initial_last_seen)
        expect(conversation.reload.agent_last_seen_at).to be > initial_last_seen
      end

      it 'refreshes unread count cache when conversation is marked read' do
        account.enable_features!(:conversation_unread_counts)
        conversation.update!(agent_last_seen_at: 1.hour.ago)
        create(:message, account: account, inbox: conversation.inbox, conversation: conversation, message_type: :incoming, created_at: 5.minutes.ago)
        Conversations::UnreadCounts::Builder.new(account).build_base!

        post "/api/v1/accounts/#{account.id}/conversations/#{conversation.display_id}/update_last_seen",
             headers: agent.create_new_auth_token,
             as: :json

        inbox_key = Conversations::UnreadCounts::Store.inbox_key(account.id, conversation.inbox_id)
        expect(response).to have_http_status(:success)
        expect(Conversations::UnreadCounts::Store.counts_for_keys([inbox_key])).to eq(inbox_key => 0)
      ensure
        Conversations::UnreadCounts::Store.clear_account!(account.id)
      end

      it 'refreshes unread count cache before invalidating filtered counts when conversation is marked read' do
        account.enable_features!(:conversation_unread_counts, :unread_count_for_filters)
        conversation.update!(agent_last_seen_at: 1.hour.ago)
        create(:message, account: account, inbox: conversation.inbox, conversation: conversation, message_type: :incoming, created_at: 5.minutes.ago)
        notifier = instance_double(Conversations::UnreadCounts::Notifier)
        invalidator = instance_double(Conversations::UnreadCounts::FilteredCountInvalidator)

        allow(Conversations::UnreadCounts::Notifier).to receive(:new).with(conversation).and_return(notifier)
        allow(Conversations::UnreadCounts::FilteredCountInvalidator).to receive(:new).with(account).and_return(invalidator)
        expect(notifier).to receive(:perform).ordered.and_return(true)
        expect(invalidator).to receive(:conversation_changed!).ordered.and_return(true)

        post "/api/v1/accounts/#{account.id}/conversations/#{conversation.display_id}/update_last_seen",
             headers: agent.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:success)
      end

      it 'invalidates filtered unread counts when conversation is marked read' do
        conversation.update!(agent_last_seen_at: 1.hour.ago)
        create(:message, account: account, inbox: conversation.inbox, conversation: conversation, message_type: :incoming, created_at: 5.minutes.ago)
        account.enable_features!(:unread_count_for_filters)

        expect do
          post "/api/v1/accounts/#{account.id}/conversations/#{conversation.display_id}/update_last_seen",
               headers: agent.create_new_auth_token,
               as: :json
        end.to change { Conversations::UnreadCounts::FilteredCountStore.conversation_version(account.id) }.by(1)
        expect(response).to have_http_status(:success)
      end

      it 'notifies clients when marking read only affects filtered counts' do
        account.enable_features!(:conversation_unread_counts, :unread_count_for_filters)
        conversation.update!(agent_last_seen_at: 1.hour.ago)
        create(:message, account: account, inbox: conversation.inbox, conversation: conversation, message_type: :incoming, created_at: 5.minutes.ago)
        allow(Conversations::UnreadCounts::Refresher).to receive(:new).and_return(
          instance_double(Conversations::UnreadCounts::Refresher, perform: false)
        )
        allow(Rails.configuration.dispatcher).to receive(:dispatch)

        post "/api/v1/accounts/#{account.id}/conversations/#{conversation.display_id}/update_last_seen",
             headers: agent.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:success)
        expect(Rails.configuration.dispatcher).to have_received(:dispatch).with(
          'conversation.unread_count_changed',
          kind_of(Time),
          conversation: conversation
        )
      end

      it 'updates both if one timestamp is old even when the other is recent' do
        conversation.update!(assignee_id: agent.id, agent_last_seen_at: 2.hours.ago, assignee_last_seen_at: 30.minutes.ago)
        # Ensure all messages are older than assignee_last_seen_at (no unread messages)
        # rubocop:disable Rails/SkipsModelValidations
        conversation.messages.update_all(created_at: 1.hour.ago)
        # rubocop:enable Rails/SkipsModelValidations

        initial_agent_last_seen = conversation.agent_last_seen_at

        post "/api/v1/accounts/#{account.id}/conversations/#{conversation.display_id}/update_last_seen",
             headers: agent.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:success)
        # Both should be updated because agent_last_seen_at is old
        expect(conversation.reload.agent_last_seen_at).to be > initial_agent_last_seen
        expect(conversation.reload.assignee_last_seen_at).to be > initial_agent_last_seen
      end

      it 'throttles only when both timestamps are recent and no unread messages' do
        conversation.update!(assignee_id: agent.id, agent_last_seen_at: 30.minutes.ago, assignee_last_seen_at: 30.minutes.ago,
                             last_activity_at: 31.minutes.ago)
        # Ensure all messages are older (no unread messages)
        # rubocop:disable Rails/SkipsModelValidations
        conversation.messages.update_all(created_at: 1.hour.ago)
        # rubocop:enable Rails/SkipsModelValidations

        initial_agent_last_seen = conversation.agent_last_seen_at
        initial_assignee_last_seen = conversation.assignee_last_seen_at

        post "/api/v1/accounts/#{account.id}/conversations/#{conversation.display_id}/update_last_seen",
             headers: agent.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:success)
        # Both should remain unchanged (throttled)
        expect(conversation.reload.agent_last_seen_at).to be_within(1.second).of(initial_agent_last_seen)
        expect(conversation.reload.assignee_last_seen_at).to be_within(1.second).of(initial_assignee_last_seen)
      end

      it 'dispatches messages.read event when user is assignee' do
        freeze_time

        previous_agent_last_seen_at = 1.hour.ago
        conversation.update!(agent_last_seen_at: previous_agent_last_seen_at, assignee: agent)

        allow(Rails.configuration.dispatcher).to receive(:dispatch)

        post "/api/v1/accounts/#{account.id}/conversations/#{conversation.display_id}/update_last_seen",
             headers: agent.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:success)
        expect(Rails.configuration.dispatcher)
          .to have_received(:dispatch)
          .with(Events::Types::MESSAGES_READ, Time.zone.now, conversation: conversation, last_seen_at: previous_agent_last_seen_at)
      end

      it 'does not dispatch messages.read event when user is not assignee' do
        allow(Rails.configuration.dispatcher).to receive(:dispatch)

        post "/api/v1/accounts/#{account.id}/conversations/#{conversation.display_id}/update_last_seen",
             headers: agent.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:success)
        expect(Rails.configuration.dispatcher).not_to have_received(:dispatch)
      end
    end
  end

  describe 'POST /api/v1/accounts/{account.id}/conversations/:id/read_receipt' do
    let(:inbox) { create(:inbox, account: account) }
    let(:conversation) { create(:conversation, account: account, inbox: inbox) }
    let(:agent_bot) { create(:agent_bot, account: account) }

    before { create(:agent_bot_inbox, inbox: inbox, agent_bot: agent_bot) }

    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        post "/api/v1/accounts/#{account.id}/conversations/#{conversation.display_id}/read_receipt"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an agent bot' do
      let!(:first_message) { create(:message, account: account, inbox: inbox, conversation: conversation, message_type: :incoming) }
      let!(:last_message) { create(:message, account: account, inbox: inbox, conversation: conversation, message_type: :incoming) }

      before { allow(Rails.configuration.dispatcher).to receive(:dispatch) }

      it 'dispatches messages.read for every unacknowledged incoming message' do
        post "/api/v1/accounts/#{account.id}/conversations/#{conversation.display_id}/read_receipt",
             headers: { api_access_token: agent_bot.access_token.token },
             as: :json

        expect(response).to have_http_status(:success)
        expect(Rails.configuration.dispatcher)
          .to have_received(:dispatch)
          .with(Events::Types::MESSAGES_READ, kind_of(Time), conversation: conversation,
                                                             message_ids: [first_message.id, last_message.id])
      end

      it 'leaves out the messages the provider has already echoed a receipt for' do
        first_message.update!(status: :read)

        post "/api/v1/accounts/#{account.id}/conversations/#{conversation.display_id}/read_receipt",
             headers: { api_access_token: agent_bot.access_token.token },
             as: :json

        expect(response).to have_http_status(:success)
        expect(Rails.configuration.dispatcher)
          .to have_received(:dispatch)
          .with(Events::Types::MESSAGES_READ, kind_of(Time), conversation: conversation, message_ids: [last_message.id])
      end

      it 'keeps only the newest of a backlog larger than the cap' do
        stub_const('Api::V1::Accounts::ConversationsController::READ_RECEIPT_BATCH_SIZE', 1)

        post "/api/v1/accounts/#{account.id}/conversations/#{conversation.display_id}/read_receipt",
             headers: { api_access_token: agent_bot.access_token.token },
             as: :json

        expect(response).to have_http_status(:success)
        expect(Rails.configuration.dispatcher)
          .to have_received(:dispatch)
          .with(Events::Types::MESSAGES_READ, kind_of(Time), conversation: conversation, message_ids: [last_message.id])
      end

      # The window is over the thread, not over its unread messages. Anchored to the unread ones
      # instead, the echo that marks this call's batch read hands the next call the batch before
      # it, and a bot answering every message pages backwards through the whole history.
      it 'never reaches past the window once the newest messages are acknowledged' do
        stub_const('Api::V1::Accounts::ConversationsController::READ_RECEIPT_BATCH_SIZE', 1)
        last_message.update!(status: :read)

        post "/api/v1/accounts/#{account.id}/conversations/#{conversation.display_id}/read_receipt",
             headers: { api_access_token: agent_bot.access_token.token },
             as: :json

        expect(response).to have_http_status(:success)
        expect(Rails.configuration.dispatcher).not_to have_received(:dispatch).with(Events::Types::MESSAGES_READ, any_args)
      end

      it 'dispatches messages.read for the message ids it was given' do
        post "/api/v1/accounts/#{account.id}/conversations/#{conversation.display_id}/read_receipt",
             params: { message_ids: [first_message.id] },
             headers: { api_access_token: agent_bot.access_token.token },
             as: :json

        expect(response).to have_http_status(:success)
        expect(Rails.configuration.dispatcher)
          .to have_received(:dispatch)
          .with(Events::Types::MESSAGES_READ, kind_of(Time), conversation: conversation, message_ids: [first_message.id])
      end

      # An empty list is a caller saying it processed nothing, not a caller saying nothing.
      # Read as the latter it would acknowledge the whole window on its own initiative.
      it 'sends no receipt when the caller names an empty list' do
        post "/api/v1/accounts/#{account.id}/conversations/#{conversation.display_id}/read_receipt",
             params: { message_ids: [] },
             headers: { api_access_token: agent_bot.access_token.token },
             as: :json

        expect(response).to have_http_status(:success)
        expect(Rails.configuration.dispatcher).not_to have_received(:dispatch).with(Events::Types::MESSAGES_READ, any_args)
      end

      it 'ignores message ids belonging to another conversation' do
        other_message = create(:message, account: account, message_type: :incoming)

        post "/api/v1/accounts/#{account.id}/conversations/#{conversation.display_id}/read_receipt",
             params: { message_ids: [other_message.id] },
             headers: { api_access_token: agent_bot.access_token.token },
             as: :json

        expect(response).to have_http_status(:success)
        expect(Rails.configuration.dispatcher).not_to have_received(:dispatch).with(Events::Types::MESSAGES_READ, any_args)
      end

      it 'leaves the dashboard read state untouched' do
        expect do
          post "/api/v1/accounts/#{account.id}/conversations/#{conversation.display_id}/read_receipt",
               headers: { api_access_token: agent_bot.access_token.token },
               as: :json
        end.to not_change { conversation.reload.agent_last_seen_at }
          .and(not_change { conversation.reload.assignee_last_seen_at })
      end

      # An imported row carries WhatsApp's own timestamp, which has second precision, so a
      # burst inside one second ties. Ordered by time alone the window is free to land on a
      # different subset of the tied rows each call, which walks past the cap over time.
      it 'picks the same window when the timestamps tie' do
        stub_const('Api::V1::Accounts::ConversationsController::READ_RECEIPT_BATCH_SIZE', 2)
        tied = Time.zone.parse('2026-01-01 10:00:00')
        [first_message, last_message].each { |m| m.update!(created_at: tied) }
        extra = create(:message, account: account, inbox: inbox, conversation: conversation, message_type: :incoming,
                                 created_at: tied)

        dispatched = []
        allow(Rails.configuration.dispatcher).to receive(:dispatch) do |event, _time, payload|
          dispatched << payload[:message_ids] if event == Events::Types::MESSAGES_READ
        end

        3.times do
          post "/api/v1/accounts/#{account.id}/conversations/#{conversation.display_id}/read_receipt",
               headers: { api_access_token: agent_bot.access_token.token },
               as: :json
        end

        expect(dispatched).to eq(Array.new(3) { [last_message.id, extra.id] })
      end

      it 'refuses a batch larger than the cap' do
        post "/api/v1/accounts/#{account.id}/conversations/#{conversation.display_id}/read_receipt",
             params: { message_ids: (1..51).to_a },
             headers: { api_access_token: agent_bot.access_token.token },
             as: :json

        expect(response).to have_http_status(:unprocessable_entity)
        expect(Rails.configuration.dispatcher).not_to have_received(:dispatch).with(Events::Types::MESSAGES_READ, any_args)
      end

      it 'denies a bot whose inbox association was switched off' do
        inactive_bot = create(:agent_bot, account: account)
        create(:agent_bot_inbox, inbox: inbox, agent_bot: inactive_bot, status: :inactive)

        post "/api/v1/accounts/#{account.id}/conversations/#{conversation.display_id}/read_receipt",
             headers: { api_access_token: inactive_bot.access_token.token },
             as: :json

        expect(response).to have_http_status(:unauthorized)
        expect(Rails.configuration.dispatcher).not_to have_received(:dispatch).with(Events::Types::MESSAGES_READ, any_args)
      end

      it 'denies a bot that serves no inbox on the conversation' do
        other_bot = create(:agent_bot, account: account)

        post "/api/v1/accounts/#{account.id}/conversations/#{conversation.display_id}/read_receipt",
             headers: { api_access_token: other_bot.access_token.token },
             as: :json

        expect(response).to have_http_status(:unauthorized)
        expect(response.parsed_body['error']).to eq('You are not authorized to do this action')
        expect(Rails.configuration.dispatcher).not_to have_received(:dispatch).with(Events::Types::MESSAGES_READ, any_args)
      end
    end

    context 'when it is an authenticated user' do
      let(:agent) { create(:user, account: account, role: :agent) }

      before do
        create(:inbox_member, user: agent, inbox: inbox)
        allow(Rails.configuration.dispatcher).to receive(:dispatch)
      end

      it 'dispatches messages.read without touching the last seen timestamps' do
        message = create(:message, account: account, inbox: inbox, conversation: conversation, message_type: :incoming)

        expect do
          post "/api/v1/accounts/#{account.id}/conversations/#{conversation.display_id}/read_receipt",
               headers: agent.create_new_auth_token,
               as: :json
        end.to(not_change { conversation.reload.agent_last_seen_at })

        expect(response).to have_http_status(:success)
        expect(Rails.configuration.dispatcher)
          .to have_received(:dispatch)
          .with(Events::Types::MESSAGES_READ, kind_of(Time), conversation: conversation, message_ids: [message.id])
      end

      it 'does not dispatch when the conversation has no incoming message' do
        post "/api/v1/accounts/#{account.id}/conversations/#{conversation.display_id}/read_receipt",
             headers: agent.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:success)
        expect(Rails.configuration.dispatcher).not_to have_received(:dispatch).with(Events::Types::MESSAGES_READ, any_args)
      end
    end
  end

  describe 'POST /api/v1/accounts/{account.id}/conversations/:id/unread' do
    let(:conversation) { create(:conversation, account: account) }

    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        post "/api/v1/accounts/#{account.id}/conversations/#{conversation.display_id}/unread"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      let(:agent) { create(:user, account: account, role: :agent) }

      before do
        create(:inbox_member, user: agent, inbox: conversation.inbox)
        create(:message, conversation: conversation, account: account, inbox: conversation.inbox, content: 'Hello', message_type: 'incoming')
      end

      it 'dispatches conversation.unread event' do
        freeze_time
        allow(Rails.configuration.dispatcher).to receive(:dispatch)
          .with(Events::Types::CONVERSATION_UNREAD, Time.zone.now, conversation: conversation)

        post "/api/v1/accounts/#{account.id}/conversations/#{conversation.display_id}/unread",
             headers: agent.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:success)
        expect(Rails.configuration.dispatcher).to have_received(:dispatch)
      end

      it 'updates last seen' do
        post "/api/v1/accounts/#{account.id}/conversations/#{conversation.display_id}/unread",
             headers: agent.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:success)
        last_seen_at = conversation.messages.incoming.last.created_at - 1.second
        expect(conversation.reload.agent_last_seen_at).to eq(last_seen_at)
        expect(conversation.reload.assignee_last_seen_at).to eq(last_seen_at)
      end

      it 'refreshes unread count cache when conversation is marked unread' do
        account.enable_features!(:conversation_unread_counts)
        conversation.update!(agent_last_seen_at: 1.minute.from_now, assignee_last_seen_at: 1.minute.from_now)
        Conversations::UnreadCounts::Builder.new(account).build_base!

        post "/api/v1/accounts/#{account.id}/conversations/#{conversation.display_id}/unread",
             headers: agent.create_new_auth_token,
             as: :json

        inbox_key = Conversations::UnreadCounts::Store.inbox_key(account.id, conversation.inbox_id)
        expect(response).to have_http_status(:success)
        expect(Conversations::UnreadCounts::Store.counts_for_keys([inbox_key])).to eq(inbox_key => 1)
      ensure
        Conversations::UnreadCounts::Store.clear_account!(account.id)
      end

      it 'refreshes unread count cache before invalidating filtered counts when conversation is marked unread' do
        account.enable_features!(:conversation_unread_counts, :unread_count_for_filters)
        conversation.update!(agent_last_seen_at: 1.minute.from_now, assignee_last_seen_at: 1.minute.from_now)
        notifier = instance_double(Conversations::UnreadCounts::Notifier)
        invalidator = instance_double(Conversations::UnreadCounts::FilteredCountInvalidator)

        allow(Conversations::UnreadCounts::Notifier).to receive(:new).with(conversation).and_return(notifier)
        allow(Conversations::UnreadCounts::FilteredCountInvalidator).to receive(:new).with(account).and_return(invalidator)
        expect(notifier).to receive(:perform).ordered.and_return(true)
        expect(invalidator).to receive(:conversation_changed!).ordered.and_return(true)

        post "/api/v1/accounts/#{account.id}/conversations/#{conversation.display_id}/unread",
             headers: agent.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:success)
      end

      it 'invalidates filtered unread counts when conversation is marked unread' do
        conversation.update!(agent_last_seen_at: 1.minute.from_now, assignee_last_seen_at: 1.minute.from_now)
        account.enable_features!(:unread_count_for_filters)

        expect do
          post "/api/v1/accounts/#{account.id}/conversations/#{conversation.display_id}/unread",
               headers: agent.create_new_auth_token,
               as: :json
        end.to change { Conversations::UnreadCounts::FilteredCountStore.conversation_version(account.id) }.by(1)
        expect(response).to have_http_status(:success)
      end

      it 'notifies clients when marking unread only affects filtered counts' do
        account.enable_features!(:conversation_unread_counts, :unread_count_for_filters)
        conversation.update!(agent_last_seen_at: 1.minute.from_now, assignee_last_seen_at: 1.minute.from_now)
        allow(Conversations::UnreadCounts::Refresher).to receive(:new).and_return(
          instance_double(Conversations::UnreadCounts::Refresher, perform: false)
        )
        allow(Rails.configuration.dispatcher).to receive(:dispatch)

        post "/api/v1/accounts/#{account.id}/conversations/#{conversation.display_id}/unread",
             headers: agent.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:success)
        expect(Rails.configuration.dispatcher).to have_received(:dispatch).with(
          'conversation.unread_count_changed',
          kind_of(Time),
          conversation: conversation
        )
      end
    end
  end

  describe 'POST /api/v1/accounts/{account.id}/conversations/:id/pin' do
    let(:conversation) { create(:conversation, account: account) }
    let(:agent) { create(:user, account: account, role: :agent) }

    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        post "/api/v1/accounts/#{account.id}/conversations/#{conversation.display_id}/pin"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when the agent has no access to the conversation' do
      it 'returns unauthorized' do
        post "/api/v1/accounts/#{account.id}/conversations/#{conversation.display_id}/pin",
             headers: agent.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an agent bot' do
      let(:agent_bot) { create(:agent_bot, account: account) }

      before { create(:agent_bot_inbox, inbox: conversation.inbox, agent_bot: agent_bot) }

      it 'returns unauthorized' do
        post "/api/v1/accounts/#{account.id}/conversations/#{conversation.display_id}/pin",
             headers: { api_access_token: agent_bot.access_token.token },
             as: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      before { create(:inbox_member, user: agent, inbox: conversation.inbox) }

      it 'pins the conversation for the current agent' do
        post "/api/v1/accounts/#{account.id}/conversations/#{conversation.display_id}/pin",
             headers: agent.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:success)
        expect(response.parsed_body['conversation_id']).to eq(conversation.display_id)
        expect(response.parsed_body['pinned_at']).to be_present
        expect(conversation.conversation_pins.pluck(:user_id)).to eq([agent.id])
      end

      it 'is idempotent' do
        2.times do
          post "/api/v1/accounts/#{account.id}/conversations/#{conversation.display_id}/pin",
               headers: agent.create_new_auth_token,
               as: :json
        end

        expect(response).to have_http_status(:success)
        expect(conversation.conversation_pins.count).to eq(1)
      end

      it 'returns unprocessable entity for a resolved conversation' do
        conversation.update!(status: :resolved)

        post "/api/v1/accounts/#{account.id}/conversations/#{conversation.display_id}/pin",
             headers: agent.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.parsed_body['message']).to eq('A resolved conversation cannot be pinned.')
      end

      it 'returns unprocessable entity when the limit is reached' do
        pinned_inbox = create(:inbox, account: account, enable_auto_assignment: false)
        create(:inbox_member, user: agent, inbox: pinned_inbox)
        ConversationPin::MAX_PER_USER.times do
          pinned = create(:conversation, account: account, inbox: pinned_inbox)
          create(:conversation_pin, conversation: pinned, user: agent, account: account)
        end

        post "/api/v1/accounts/#{account.id}/conversations/#{conversation.display_id}/pin",
             headers: agent.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.parsed_body['message']).to eq("You can pin up to #{ConversationPin::MAX_PER_USER} conversations.")
      end
    end
  end

  describe 'DELETE /api/v1/accounts/{account.id}/conversations/:id/unpin' do
    let(:conversation) { create(:conversation, account: account) }
    let(:agent) { create(:user, account: account, role: :agent) }

    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        delete "/api/v1/accounts/#{account.id}/conversations/#{conversation.display_id}/unpin"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      before { create(:inbox_member, user: agent, inbox: conversation.inbox) }

      it 'removes only the pin of the current agent' do
        other_agent = create(:user, account: account, role: :agent)
        create(:inbox_member, user: other_agent, inbox: conversation.inbox)
        create(:conversation_pin, conversation: conversation, user: agent, account: account)
        create(:conversation_pin, conversation: conversation, user: other_agent, account: account)

        delete "/api/v1/accounts/#{account.id}/conversations/#{conversation.display_id}/unpin",
               headers: agent.create_new_auth_token,
               as: :json

        expect(response).to have_http_status(:success)
        expect(conversation.conversation_pins.pluck(:user_id)).to eq([other_agent.id])
      end

      it 'succeeds when the conversation is not pinned' do
        delete "/api/v1/accounts/#{account.id}/conversations/#{conversation.display_id}/unpin",
               headers: agent.create_new_auth_token,
               as: :json

        expect(response).to have_http_status(:success)
      end

      it 'still removes the pin after the agent loses access to the inbox' do
        create(:conversation_pin, conversation: conversation, user: agent, account: account)
        agent.inbox_members.destroy_all

        delete "/api/v1/accounts/#{account.id}/conversations/#{conversation.display_id}/unpin",
               headers: agent.create_new_auth_token,
               as: :json

        expect(response).to have_http_status(:success)
        expect(conversation.conversation_pins.count).to eq(0)
      end

      it 'does not remove the pin of another agent' do
        other_agent = create(:user, account: account, role: :agent)
        create(:inbox_member, user: other_agent, inbox: conversation.inbox)
        create(:conversation_pin, conversation: conversation, user: other_agent, account: account)

        delete "/api/v1/accounts/#{account.id}/conversations/#{conversation.display_id}/unpin",
               headers: agent.create_new_auth_token,
               as: :json

        expect(conversation.conversation_pins.pluck(:user_id)).to eq([other_agent.id])
      end
    end
  end

  describe 'GET /api/v1/accounts/{account.id}/conversations/pins' do
    let(:conversation) { create(:conversation, account: account) }
    let(:agent) { create(:user, account: account, role: :agent) }

    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get "/api/v1/accounts/#{account.id}/conversations/pins"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      before { create(:inbox_member, user: agent, inbox: conversation.inbox) }

      it 'returns the pins of the current agent in the current account' do
        pin = create(:conversation_pin, conversation: conversation, user: agent, account: account)
        other_agent = create(:user, account: account, role: :agent)
        other_conversation = create(:conversation, account: account)
        create(:inbox_member, user: other_agent, inbox: other_conversation.inbox)
        create(:conversation_pin, conversation: other_conversation, user: other_agent, account: account)

        get "/api/v1/accounts/#{account.id}/conversations/pins",
            headers: agent.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        expect(response.parsed_body).to eq([{ 'conversation_id' => conversation.display_id, 'pinned_at' => pin.created_at.to_f }])
      end

      it 'skips a pin whose conversation is already gone' do
        create(:conversation_pin, conversation: conversation, user: agent, account: account)
        # `dependent: :destroy_async` leaves the pins behind until the job runs.
        Conversation.where(id: conversation.id).delete_all

        get "/api/v1/accounts/#{account.id}/conversations/pins",
            headers: agent.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        expect(response.parsed_body).to eq([])
      end

      it 'returns an empty list when nothing is pinned' do
        get "/api/v1/accounts/#{account.id}/conversations/pins",
            headers: agent.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        expect(response.parsed_body).to eq([])
      end
    end
  end

  describe 'POST /api/v1/accounts/{account.id}/conversations/:id/mute' do
    let(:conversation) { create(:conversation, account: account) }

    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        post "/api/v1/accounts/#{account.id}/conversations/#{conversation.display_id}/mute"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      let(:agent) { create(:user, account: account, role: :agent) }

      before do
        create(:inbox_member, user: agent, inbox: conversation.inbox)
      end

      it 'mutes conversation' do
        post "/api/v1/accounts/#{account.id}/conversations/#{conversation.display_id}/mute",
             headers: agent.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:success)
        expect(conversation.reload.resolved?).to be(true)
        expect(conversation.reload.muted?).to be(true)
      end
    end
  end

  describe 'POST /api/v1/accounts/{account.id}/conversations/:id/unmute' do
    let(:conversation) { create(:conversation, account: account).tap(&:mute!) }

    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        post "/api/v1/accounts/#{account.id}/conversations/#{conversation.display_id}/unmute"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      let(:agent) { create(:user, account: account, role: :agent) }

      before do
        create(:inbox_member, user: agent, inbox: conversation.inbox)
      end

      it 'unmutes conversation' do
        post "/api/v1/accounts/#{account.id}/conversations/#{conversation.display_id}/unmute",
             headers: agent.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:success)
        expect(conversation.reload.muted?).to be(false)
      end
    end
  end

  describe 'POST /api/v1/accounts/{account.id}/conversations/:id/sync_history' do
    let(:channel) do
      create(:channel_whatsapp, account: account, provider: 'baileys', validate_provider_config: false, sync_templates: false,
                                provider_config: { 'webhook_verify_token' => 'x' },
                                provider_connection: { 'connection' => 'open' })
    end
    let(:conversation) { create(:conversation, account: account, inbox: channel.inbox) }
    let(:url) { "/api/v1/accounts/#{account.id}/conversations/#{conversation.display_id}/sync_history" }

    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        post url

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      let(:agent) { create(:user, account: account, role: :agent) }

      before { create(:inbox_member, user: agent, inbox: conversation.inbox) }

      # Whoever is reading the thread is who wants its history, so this is not held to the
      # administrator bar the inbox-wide setting is.
      it 'asks the provider for what came before' do
        expect do
          post url, headers: agent.create_new_auth_token, as: :json
        end.to have_enqueued_job(Whatsapp::Session::ConversationHistoryJob).with(conversation)

        expect(response).to have_http_status(:success)
      end

      # The request reaches the phone through the session, so a closed one would have the
      # operator told it was asked and nothing would ever arrive.
      it 'refuses while the session is down' do
        channel.update!(provider_connection: { 'connection' => 'close' })

        expect do
          post url, headers: agent.create_new_auth_token, as: :json
        end.not_to have_enqueued_job(Whatsapp::Session::ConversationHistoryJob)

        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'refuses on an inbox whose provider cannot fetch history' do
        other = create(:conversation, account: account, inbox: create(:inbox, account: account))
        create(:inbox_member, user: agent, inbox: other.inbox)

        post "/api/v1/accounts/#{account.id}/conversations/#{other.display_id}/sync_history",
             headers: agent.create_new_auth_token, as: :json

        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  # A number with no WhatsApp account takes the server's single check and then reaches nobody,
  # so a conversation started against one has to say so (fazer-ai/chatwoot#877).
  describe 'WhatsApp number with no account' do
    let(:channel) do
      create(:channel_whatsapp, account: account, provider: 'baileys', validate_provider_config: false, sync_templates: false,
                                provider_connection: { 'connection' => 'open' })
    end
    let(:agent) { create(:user, account: account, role: :agent) }
    let(:contact) { create(:contact, account: account, phone_number: '+558588246590') }

    before { create(:inbox_member, user: agent, inbox: channel.inbox) }

    it 'flags the conversation an agent starts against a number WhatsApp does not know' do
      allow_any_instance_of(Channel::Whatsapp).to receive(:on_whatsapp) # rubocop:disable RSpec/AnyInstance
        .and_return({ 'jid' => '558588246590@s.whatsapp.net', 'exists' => false })

      freeze_time do
        post "/api/v1/accounts/#{account.id}/conversations",
             params: { inbox_id: channel.inbox.id, contact_id: contact.id, source_id: '558588246590', message: { content: 'Boa tarde' } },
             headers: agent.create_new_auth_token, as: :json

        expect(response).to have_http_status(:success)
        expect(response.parsed_body['whatsapp_missing_checked_at']).to eq(Time.current.to_i)
      end
    end

    it 'leaves the field empty when WhatsApp knows the number' do
      allow_any_instance_of(Channel::Whatsapp).to receive(:on_whatsapp) # rubocop:disable RSpec/AnyInstance
        .and_return({ 'jid' => '558588246590@s.whatsapp.net', 'exists' => true })

      post "/api/v1/accounts/#{account.id}/conversations",
           params: { inbox_id: channel.inbox.id, contact_id: contact.id, source_id: '558588246590', message: { content: 'Boa tarde' } },
           headers: agent.create_new_auth_token, as: :json

      expect(response).to have_http_status(:success)
      expect(response.parsed_body).to include('whatsapp_missing_checked_at' => nil)
    end

    describe 'POST /api/v1/accounts/{account.id}/conversations/:id/recheck_whatsapp_number' do
      let(:contact_inbox) { create(:contact_inbox, contact: contact, inbox: channel.inbox, source_id: '558588246590') }
      let(:conversation) { create(:conversation, account: account, inbox: channel.inbox, contact: contact, contact_inbox: contact_inbox) }
      let(:url) { "/api/v1/accounts/#{account.id}/conversations/#{conversation.display_id}/recheck_whatsapp_number" }

      it 'returns unauthorized to an agent outside the inbox' do
        outsider = create(:user, account: account, role: :agent)
        contact_inbox.update!(whatsapp_missing_checked_at: 2.days.ago)

        expect do
          post url, headers: outsider.create_new_auth_token, as: :json
        end.not_to have_enqueued_job(Whatsapp::NumberRecheckJob)

        expect(response).to have_http_status(:unauthorized)
      end

      it 'asks again once the flag is older than the recheck window' do
        contact_inbox.update!(whatsapp_missing_checked_at: 2.days.ago)

        expect do
          post url, headers: agent.create_new_auth_token, as: :json
        end.to have_enqueued_job(Whatsapp::NumberRecheckJob).with(conversation)

        expect(response).to have_http_status(:accepted)
      end

      # Every open of a flagged conversation calls this; within the window it must cost nothing.
      it 'does not ask again inside the recheck window' do
        contact_inbox.update!(whatsapp_missing_checked_at: 10.minutes.ago)

        expect do
          post url, headers: agent.create_new_auth_token, as: :json
        end.not_to have_enqueued_job(Whatsapp::NumberRecheckJob)

        expect(response).to have_http_status(:accepted)
      end
    end
  end

  describe 'POST /api/v1/accounts/{account.id}/conversations/:id/transcript' do
    let(:conversation) { create(:conversation, account: account) }

    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        post "/api/v1/accounts/#{account.id}/conversations/#{conversation.display_id}/transcript"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      let(:agent) { create(:user, account: account, role: :agent) }
      let(:params) { { email: 'test@test.com' } }

      before do
        create(:inbox_member, user: agent, inbox: conversation.inbox)
      end

      it 'mutes conversation' do
        mailer = double
        allow(ConversationReplyMailer).to receive(:with).and_return(mailer)
        allow(mailer).to receive(:conversation_transcript)
        post "/api/v1/accounts/#{account.id}/conversations/#{conversation.display_id}/transcript",
             headers: agent.create_new_auth_token,
             params: params,
             as: :json

        expect(response).to have_http_status(:success)
        expect(mailer).to have_received(:conversation_transcript).with(conversation, 'test@test.com')
      end

      it 'renders error when parameter missing' do
        post "/api/v1/accounts/#{account.id}/conversations/#{conversation.display_id}/transcript",
             headers: agent.create_new_auth_token,
             params: {},
             as: :json
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe 'POST /api/v1/accounts/{account.id}/conversations/:id/custom_attributes' do
    let(:conversation) { create(:conversation, account: account) }

    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        post "/api/v1/accounts/#{account.id}/conversations/#{conversation.display_id}/custom_attributes"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      let(:agent) { create(:user, account: account, role: :agent) }
      let(:custom_attributes) { { user_id: 1001, created_date: '23/12/2012', subscription_id: 12 } }
      let(:valid_params) { { custom_attributes: custom_attributes } }

      before do
        create(:inbox_member, user: agent, inbox: conversation.inbox)
      end

      it 'updates custom attributes' do
        post "/api/v1/accounts/#{account.id}/conversations/#{conversation.display_id}/custom_attributes",
             headers: agent.create_new_auth_token,
             params: valid_params,
             as: :json

        expect(response).to have_http_status(:success)
        expect(conversation.reload.custom_attributes).not_to be_nil
        expect(conversation.reload.custom_attributes.count).to eq 3
      end

      it 'merges custom attributes when merge is enabled' do
        conversation.update!(custom_attributes: { existing_key: 'keep', user_id: 1 })

        post "/api/v1/accounts/#{account.id}/conversations/#{conversation.display_id}/custom_attributes",
             headers: agent.create_new_auth_token,
             params: { custom_attributes: { user_id: 1001 }, merge: true },
             as: :json

        expect(response).to have_http_status(:success)
        expect(conversation.reload.custom_attributes).to eq({ 'existing_key' => 'keep', 'user_id' => 1001 })
      end

      it 'replaces custom attributes by default' do
        conversation.update!(custom_attributes: { existing_key: 'gone' })

        post "/api/v1/accounts/#{account.id}/conversations/#{conversation.display_id}/custom_attributes",
             headers: agent.create_new_auth_token,
             params: { custom_attributes: { user_id: 1001 } },
             as: :json

        expect(response).to have_http_status(:success)
        expect(conversation.reload.custom_attributes).to eq({ 'user_id' => 1001 })
      end
    end

    context 'when it is a bot' do
      let(:agent_bot) { create(:agent_bot, account: account) }
      let(:custom_attributes) { { bot_id: 1001, flow_name: 'support_flow', step: 'greeting' } }
      let(:valid_params) { { custom_attributes: custom_attributes } }

      before do
        create(:agent_bot_inbox, agent_bot: agent_bot, inbox: conversation.inbox)
      end

      it 'updates custom attributes' do
        post "/api/v1/accounts/#{account.id}/conversations/#{conversation.display_id}/custom_attributes",
             headers: { api_access_token: agent_bot.access_token.token },
             params: valid_params,
             as: :json

        expect(response).to have_http_status(:success)
        expect(conversation.reload.custom_attributes).not_to be_nil
        expect(conversation.reload.custom_attributes.count).to eq 3
      end
    end
  end

  describe 'POST /api/v1/accounts/{account.id}/conversations/:id/destroy_custom_attributes' do
    let(:conversation) { create(:conversation, account: account, custom_attributes: { test: 'test', test1: 'test1' }) }

    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        post "/api/v1/accounts/#{account.id}/conversations/#{conversation.display_id}/destroy_custom_attributes"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      let(:agent) { create(:user, account: account, role: :agent) }

      before do
        create(:inbox_member, user: agent, inbox: conversation.inbox)
      end

      it 'deletes the given custom attribute' do
        post "/api/v1/accounts/#{account.id}/conversations/#{conversation.display_id}/destroy_custom_attributes",
             headers: agent.create_new_auth_token,
             params: { custom_attributes: ['test'] },
             as: :json

        expect(response).to have_http_status(:ok)
        expect(conversation.reload.custom_attributes).to eq({ 'test1' => 'test1' })
        expect(response.parsed_body['custom_attributes']).to eq({ 'test1' => 'test1' })
      end
    end
  end

  describe 'GET /api/v1/accounts/{account.id}/conversations/:id/attachments' do
    let(:conversation) { create(:conversation, account: account) }

    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get "/api/v1/accounts/#{account.id}/conversations/#{conversation.display_id}/attachments"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      let(:agent) { create(:user, account: account, role: :agent) }
      let(:administrator) { create(:user, account: account, role: :administrator) }

      before do
        create(:message, :with_attachment, conversation: conversation, account: account, inbox: conversation.inbox, message_type: 'incoming')
      end

      it 'does not return the attachments if you do not have access to it' do
        get "/api/v1/accounts/#{account.id}/conversations/#{conversation.display_id}/attachments",
            headers: agent.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:unauthorized)
      end

      it 'return the attachments if you are an administrator' do
        get "/api/v1/accounts/#{account.id}/conversations/#{conversation.display_id}/attachments",
            headers: administrator.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        response_body = response.parsed_body
        attachment = conversation.messages.last.attachments.first
        expect(response_body['payload'].first['id']).to eq(attachment.id)
        expect(response_body['payload'].first['file_type']).to eq('image')
        expect(response_body['payload'].first['sender']['id']).to eq(conversation.messages.last.sender.id)
      end

      it 'return the attachments if you are an agent with access to inbox' do
        get "/api/v1/accounts/#{account.id}/conversations/#{conversation.display_id}/attachments",
            headers: administrator.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        response_body = response.parsed_body
        expect(response_body['payload'].length).to eq(1)
      end
    end
  end

  describe 'DELETE /api/v1/accounts/{account.id}/conversations/:id' do
    let(:conversation) { create(:conversation, account: account) }
    let(:agent) { create(:user, account: account, role: :agent) }
    let(:administrator) { create(:user, account: account, role: :administrator) }

    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        delete "/api/v1/accounts/#{account.id}/conversations/#{conversation.display_id}"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated agent' do
      before do
        create(:inbox_member, user: agent, inbox: conversation.inbox)
      end

      it 'returns unauthorized' do
        delete "/api/v1/accounts/#{account.id}/conversations/#{conversation.display_id}",
               headers: agent.create_new_auth_token,
               as: :json

        expect(response).to have_http_status(:unauthorized)
        response_body = response.parsed_body
        expect(response_body['error']).to eq('You are not authorized to do this action')
      end
    end

    context 'when it is an authenticated administrator' do
      before do
        create(:inbox_member, user: administrator, inbox: conversation.inbox)
      end

      it 'successfully deletes the conversation' do
        expect do
          delete "/api/v1/accounts/#{account.id}/conversations/#{conversation.display_id}",
                 headers: administrator.create_new_auth_token,
                 as: :json
        end.to have_enqueued_job(DeleteObjectJob).with(conversation, administrator, anything)

        expect(response).to have_http_status(:ok)
      end

      it 'can delete conversations from inboxes without direct access' do
        other_inbox = create(:inbox, account: account)
        other_conversation = create(:conversation, account: account, inbox: other_inbox)

        expect do
          delete "/api/v1/accounts/#{account.id}/conversations/#{other_conversation.display_id}",
                 headers: administrator.create_new_auth_token,
                 as: :json
        end.to have_enqueued_job(DeleteObjectJob).with(other_conversation, administrator, anything)

        expect(response).to have_http_status(:ok)
      end
    end
  end

  describe 'POST /api/v1/accounts/{account.id}/conversations/:id/fetch_history_media' do
    let(:channel) { create(:channel_whatsapp, account: account, provider: 'native', validate_provider_config: false, sync_templates: false) }
    let(:conversation) { create(:conversation, account: account, inbox: channel.inbox) }
    let(:url) { "/api/v1/accounts/#{account.id}/conversations/#{conversation.display_id}/fetch_history_media" }
    let(:agent) { create(:user, account: account, role: :agent) }

    it 'queues the files of the conversation for whoever reads it' do
      create(:inbox_member, user: agent, inbox: channel.inbox)

      expect do
        post url, headers: agent.create_new_auth_token, as: :json
      end.to have_enqueued_job(Whatsapp::Session::ConversationHistoryMediaJob).with(conversation)

      expect(response).to have_http_status(:accepted)
    end

    it 'refuses an agent who cannot see the inbox' do
      expect do
        post url, headers: agent.create_new_auth_token, as: :json
      end.not_to have_enqueued_job(Whatsapp::Session::ConversationHistoryMediaJob)

      expect(response).to have_http_status(:unauthorized)
    end

    it 'refuses an inbox the session layer does not serve' do
      cloud = create(:channel_whatsapp, account: account, provider: 'whatsapp_cloud', validate_provider_config: false, sync_templates: false)
      create(:inbox_member, user: agent, inbox: cloud.inbox)
      other = create(:conversation, account: account, inbox: cloud.inbox)

      post "/api/v1/accounts/#{account.id}/conversations/#{other.display_id}/fetch_history_media",
           headers: agent.create_new_auth_token, as: :json

      expect(response).to have_http_status(:unprocessable_entity)
    end
  end
end
