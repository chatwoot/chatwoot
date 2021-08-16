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
        body = JSON.parse(response.body, symbolize_names: true)
        expect(body[:data][:meta][:all_count]).to eq(1)
        expect(body[:data][:meta].keys).to include(:all_count, :mine_count, :assigned_count, :unassigned_count)
        expect(body[:data][:payload].first[:messages].first[:id]).to eq(message.id)
      end

      it 'returns conversations with empty messages array for conversations with out messages ' do
        get "/api/v1/accounts/#{account.id}/conversations",
            headers: agent.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        body = JSON.parse(response.body, symbolize_names: true)
        expect(body[:data][:meta][:all_count]).to eq(1)
        expect(body[:data][:payload].first[:messages]).to eq([])
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
  end

  describe 'POST /api/v1/accounts/{account.id}/conversations' do
    let(:contact) { create(:contact, account: account) }
    let(:inbox) { create(:inbox, account: account) }
    let(:contact_inbox) { create(:contact_inbox, contact: contact, inbox: inbox) }

    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        post "/api/v1/accounts/#{account.id}/conversations",
             params: { source_id: contact_inbox.source_id },
             as: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      let(:agent) { create(:user, account: account, role: :agent) }

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
        end

        it 'creates a new conversation' do
          allow(Rails.configuration.dispatcher).to receive(:dispatch)
          additional_attributes = { test: 'test' }
          post "/api/v1/accounts/#{account.id}/conversations",
               headers: agent.create_new_auth_token,
               params: { source_id: contact_inbox.source_id, additional_attributes: additional_attributes },
               as: :json

          expect(response).to have_http_status(:success)
          response_data = JSON.parse(response.body, symbolize_names: true)
          expect(response_data[:additional_attributes]).to eq(additional_attributes)
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

        # TODO: remove this spec when we remove the condition check in controller
        # Added for backwards compatibility for bot status
        it 'creates a conversation as pending if status is specified as bot' do
          allow(Rails.configuration.dispatcher).to receive(:dispatch)
          post "/api/v1/accounts/#{account.id}/conversations",
               headers: agent.create_new_auth_token,
               params: { source_id: contact_inbox.source_id, status: 'bot' },
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
          allow(ContactInboxBuilder).to receive(:new).and_return(builder)
          allow(builder).to receive(:perform)
          expect(builder).to receive(:perform)

          post "/api/v1/accounts/#{account.id}/conversations",
               headers: agent.create_new_auth_token,
               params: { contact_id: contact.id, inbox_id: inbox.id },
               as: :json
        end
      end
    end
  end

  describe 'POST /api/v1/accounts/{account.id}/conversations/:id/toggle_status' do
    let(:conversation) { create(:conversation, account: account) }

    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        post "/api/v1/accounts/#{account.id}/conversations/#{conversation.display_id}/toggle_status"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      let(:agent) { create(:user, account: account, role: :agent) }

      before do
        create(:inbox_member, user: agent, inbox: conversation.inbox)
      end

      it 'toggles the conversation status' do
        expect(conversation.status).to eq('open')

        post "/api/v1/accounts/#{account.id}/conversations/#{conversation.display_id}/toggle_status",
             headers: agent.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:success)
        expect(conversation.reload.status).to eq('resolved')
      end

      it 'toggles the conversation status to open from pending' do
        conversation.update!(status: 'pending')

        post "/api/v1/accounts/#{account.id}/conversations/#{conversation.display_id}/toggle_status",
             headers: agent.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:success)
        expect(conversation.reload.status).to eq('open')
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

      # TODO: remove this spec when we remove the condition check in controller
      # Added for backwards compatibility for bot status
      it 'toggles the conversation status to pending status when parameter bot is passed' do
        expect(conversation.status).to eq('open')

        post "/api/v1/accounts/#{account.id}/conversations/#{conversation.display_id}/toggle_status",
             headers: agent.create_new_auth_token,
             params: { status: 'bot' },
             as: :json

        expect(response).to have_http_status(:success)
        expect(conversation.reload.status).to eq('pending')
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
             params: { typing_status: 'on' },
             as: :json

        expect(response).to have_http_status(:success)
        expect(Rails.configuration.dispatcher).to have_received(:dispatch)
          .with(Conversation::CONVERSATION_TYPING_ON, kind_of(Time), { conversation: conversation, user: agent })
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
        post "/api/v1/accounts/#{account.id}/conversations/#{conversation.display_id}/update_last_seen",
             headers: agent.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:success)
        expect(conversation.reload.agent_last_seen_at).not_to eq nil
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
        expect(conversation.reload.resolved?).to eq(true)
        expect(conversation.reload.muted?).to eq(true)
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
        expect(conversation.reload.muted?).to eq(false)
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
end
