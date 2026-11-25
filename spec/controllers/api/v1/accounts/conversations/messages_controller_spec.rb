require 'rails_helper'

RSpec.describe 'Conversation Messages API', type: :request do
  let!(:account) { create(:account) }

  describe 'POST /api/v1/accounts/{account.id}/conversations/<id>/messages' do
    let!(:inbox) { create(:inbox, account: account) }
    let!(:conversation) { create(:conversation, inbox: inbox, account: account) }

    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        post api_v1_account_conversation_messages_url(account_id: account.id, conversation_id: conversation.display_id)

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user with access to conversation' do
      let(:agent) { create(:user, account: account, role: :agent) }

      before do
        create(:inbox_member, inbox: conversation.inbox, user: agent)
      end

      it 'creates a new outgoing message' do
        params = { content: 'test-message', private: true }

        post api_v1_account_conversation_messages_url(account_id: account.id, conversation_id: conversation.display_id),
             params: params,
             headers: agent.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:success)
        expect(response).to conform_schema(200)
        expect(conversation.messages.count).to eq(1)
        expect(conversation.messages.first.content).to eq(params[:content])
      end

      it 'does not create the message' do
        params = { content: "#{'h' * 150 * 1000}a", private: true }

        post api_v1_account_conversation_messages_url(account_id: account.id, conversation_id: conversation.display_id),
             params: params,
             headers: agent.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:unprocessable_entity)

        json_response = response.parsed_body

        expect(json_response['error']).to eq('Validation failed: Content is too long (maximum is 150000 characters)')
      end

      it 'returns a customer-safe error when the database query is canceled' do
        message_builder = instance_double(Messages::MessageBuilder)
        allow(Messages::MessageBuilder).to receive(:new).and_return(message_builder)
        allow(message_builder).to receive(:perform)
          .and_raise(ActiveRecord::QueryCanceled, 'PG::QueryCanceled: ERROR: canceling statement due to statement timeout')

        post api_v1_account_conversation_messages_url(account_id: account.id, conversation_id: conversation.display_id),
             params: { content: 'test-message', private: true },
             headers: agent.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:service_unavailable)
        expect(response.headers['Retry-After']).to match(/\A[1-9]\d*\z/)
        expect(response.parsed_body['error']).to eq(I18n.t('errors.database.query_canceled'))
        expect(response.parsed_body['error']).not_to include('PG::QueryCanceled')
      end

      it 'creates an outgoing text message with a specific bot sender' do
        agent_bot = create(:agent_bot)
        time_stamp = Time.now.utc.to_s
        params = { content: 'test-message', external_created_at: time_stamp, sender_type: 'AgentBot', sender_id: agent_bot.id }

        post api_v1_account_conversation_messages_url(account_id: account.id, conversation_id: conversation.display_id),
             params: params,
             headers: agent.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:success)
        response_data = response.parsed_body
        expect(response_data['content_attributes']['external_created_at']).to eq time_stamp
        expect(conversation.messages.count).to eq(1)
        expect(conversation.messages.last.sender_id).to eq(agent_bot.id)
        expect(conversation.messages.last.content_type).to eq('text')
      end

      it 'creates a new outgoing message with attachment' do
        file = fixture_file_upload(Rails.root.join('spec/assets/avatar.png'), 'image/png')
        params = { content: 'test-message', attachments: [file] }

        post api_v1_account_conversation_messages_url(account_id: account.id, conversation_id: conversation.display_id),
             params: params,
             headers: agent.create_new_auth_token

        expect(response).to have_http_status(:success)
        expect(conversation.messages.last.attachments.first.file.present?).to be(true)
        expect(conversation.messages.last.attachments.first.file_type).to eq('image')
      end

      # The agent has to learn now, from the request they made, rather than from a failed status
      # minutes later carrying a provider error nobody can tie back to an empty file.
      it 'refuses an empty attachment without creating the message' do
        empty = Tempfile.new(['voice', '.ogg'])
        empty.close
        params = { content: nil, attachments: [Rack::Test::UploadedFile.new(empty.path, 'audio/ogg')] }

        post api_v1_account_conversation_messages_url(account_id: account.id, conversation_id: conversation.display_id),
             params: params,
             headers: agent.create_new_auth_token

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.parsed_body['error']).to include('file is empty')
        expect(conversation.messages.count).to eq(0)
      end

      it 'triggers typing off event for non-private messages' do
        params = { content: 'test-message', private: false }
        allow(Rails.configuration.dispatcher).to receive(:dispatch).and_call_original

        post api_v1_account_conversation_messages_url(account_id: account.id, conversation_id: conversation.display_id),
             params: params,
             headers: agent.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:success)
        expect(Rails.configuration.dispatcher).to have_received(:dispatch)
          .with('conversation.typing_off', kind_of(Time), hash_including(conversation: conversation, user: agent, is_private: false))
      end

      it 'triggers typing off event for private messages' do
        params = { content: 'test-message', private: true }
        allow(Rails.configuration.dispatcher).to receive(:dispatch).and_call_original

        post api_v1_account_conversation_messages_url(account_id: account.id, conversation_id: conversation.display_id),
             params: params,
             headers: agent.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:success)
        expect(Rails.configuration.dispatcher).to have_received(:dispatch)
          .with('conversation.typing_off', kind_of(Time), hash_including(conversation: conversation, user: agent, is_private: true))
      end

      context 'when forwarding an email' do
        let(:inbox) { create(:channel_email, account: account).inbox }
        let(:forwarded_message) { create(:message, conversation: conversation, account: account, message_type: :incoming) }
        let(:forwarded_attachment) do
          attachment = forwarded_message.attachments.new(account_id: account.id, file_type: :image)
          attachment.file.attach(io: Rails.root.join('spec/assets/avatar.png').open, filename: 'avatar.png', content_type: 'image/png')
          attachment.save!
          attachment
        end

        it 'creates the forward with the edited html, recipients and reused attachments' do
          params = {
            content: 'Please handle this',
            to_emails: 'vendor@example.com',
            email_html_content: '<p>Please handle this</p><p>Edited body</p>',
            content_attributes: { forwarded_message_id: forwarded_message.id }.to_json,
            forwarded_attachment_ids: [forwarded_attachment.id]
          }

          post api_v1_account_conversation_messages_url(account_id: account.id, conversation_id: conversation.display_id),
               params: params,
               headers: agent.create_new_auth_token

          expect(response).to have_http_status(:success)
          forward = conversation.messages.outgoing.last
          expect(forward.content).to eq('Please handle this')
          expect(forward.content_attributes['forwarded_message_id']).to eq(forwarded_message.id)
          expect(forward.content_attributes['to_emails']).to eq(['vendor@example.com'])
          expect(forward.content_attributes.dig('email', 'html_content', 'reply')).to eq('<p>Please handle this</p><p>Edited body</p>')
          expect(forward.attachments.map { |attachment| attachment.file.blob }).to eq([forwarded_attachment.file.blob])
        end

        it 'rejects a forwarded message that belongs to another conversation' do
          other_message = create(:message, account: account)

          post api_v1_account_conversation_messages_url(account_id: account.id, conversation_id: conversation.display_id),
               params: { content: 'Please handle this', content_attributes: { forwarded_message_id: other_message.id } },
               headers: agent.create_new_auth_token,
               as: :json

          # The fork answers a missing record with 404 everywhere (RequestExceptionHandler).
          expect(response).to have_http_status(:not_found)
          expect(conversation.messages.outgoing).to be_empty
        end

        it 'rejects a forward without a recipient' do
          post api_v1_account_conversation_messages_url(account_id: account.id, conversation_id: conversation.display_id),
               params: { content: 'Please handle this', content_attributes: { forwarded_message_id: forwarded_message.id } },
               headers: agent.create_new_auth_token,
               as: :json

          expect(response).to have_http_status(:unprocessable_entity)
          expect(response.parsed_body['error']).to eq('Forwarded emails need a recipient')
          expect(conversation.messages.outgoing).to be_empty
        end
      end

      context 'when api inbox' do
        let(:api_channel) { create(:channel_api, account: account) }
        let(:api_inbox) { create(:inbox, channel: api_channel, account: account) }
        let(:conversation) { create(:conversation, inbox: api_inbox, account: account) }

        it 'reopens the conversation with new incoming message' do
          create(:message, conversation: conversation, account: account)
          conversation.resolved!

          params = { content: 'test-message', private: false, message_type: 'incoming' }

          post api_v1_account_conversation_messages_url(account_id: account.id, conversation_id: conversation.display_id),
               params: params,
               headers: agent.create_new_auth_token,
               as: :json

          expect(response).to have_http_status(:success)
          expect(conversation.reload.status).to eq('open')
          expect(Conversations::ActivityMessageJob)
            .to(have_been_enqueued.at_least(:once)
              .with(conversation, { account_id: conversation.account_id, inbox_id: conversation.inbox_id, message_type: :activity,
                                    content: 'System reopened the conversation due to a new incoming message.',
                                    content_attributes: {
                                      activity: {
                                        type: 'conversation_status_changed',
                                        status: 'open'
                                      }
                                    } }))
        end
      end
    end

    context 'when it is an authenticated agent bot' do
      let!(:agent_bot) { create(:agent_bot) }

      it 'creates a new outgoing message' do
        create(:agent_bot_inbox, inbox: inbox, agent_bot: agent_bot)
        params = { content: 'test-message' }

        post api_v1_account_conversation_messages_url(account_id: account.id, conversation_id: conversation.display_id),
             params: params,
             headers: { api_access_token: agent_bot.access_token.token },
             as: :json

        expect(response).to have_http_status(:success)
        expect(conversation.messages.count).to eq(1)
        expect(conversation.messages.first.content).to eq(params[:content])
      end

      it 'creates a new outgoing input select message' do
        create(:agent_bot_inbox, inbox: inbox, agent_bot: agent_bot)
        select_item1 = build(:bot_message_select).merge(description: 'First option description')
        select_item2 = build(:bot_message_select)
        params = { content_type: 'input_select', content_attributes: { items: [select_item1, select_item2] } }

        post api_v1_account_conversation_messages_url(account_id: account.id, conversation_id: conversation.display_id),
             params: params,
             headers: { api_access_token: agent_bot.access_token.token },
             as: :json

        expect(response).to have_http_status(:success)
        expect(conversation.messages.count).to eq(1)
        expect(conversation.messages.first.content_type).to eq(params[:content_type])
        expect(conversation.messages.first.content).to be_nil
        expect(conversation.messages.first.content_attributes['items'].first['description']).to eq('First option description')
      end

      it 'creates a new outgoing cards message' do
        create(:agent_bot_inbox, inbox: inbox, agent_bot: agent_bot)
        card = build(:bot_message_card)
        params = { content_type: 'cards', content_attributes: { items: [card] } }

        post api_v1_account_conversation_messages_url(account_id: account.id, conversation_id: conversation.display_id),
             params: params,
             headers: { api_access_token: agent_bot.access_token.token },
             as: :json

        expect(response).to have_http_status(:success)
        expect(conversation.messages.count).to eq(1)
        expect(conversation.messages.first.content_type).to eq(params[:content_type])
      end

      it 'answers an activity message with no sender and leaves the contact last activity alone' do
        create(:agent_bot_inbox, inbox: inbox, agent_bot: agent_bot)
        conversation.contact.update!(last_activity_at: 3.days.ago)

        expect do
          post api_v1_account_conversation_messages_url(account_id: account.id, conversation_id: conversation.display_id),
               params: { content: 'Order shipped', message_type: 'activity' },
               headers: { api_access_token: agent_bot.access_token.token },
               as: :json
        end.not_to(change { conversation.contact.reload.last_activity_at })

        expect(response).to have_http_status(:success)
        expect(response.parsed_body['message_type']).to eq(2)
        expect(response.parsed_body).not_to have_key('sender')
      end
    end
  end

  describe 'GET /api/v1/accounts/{account.id}/conversations/:id/messages' do
    let(:conversation) { create(:conversation, account: account) }

    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get "/api/v1/accounts/#{account.id}/conversations/#{conversation.display_id}/messages"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user with access to conversation' do
      let(:agent) { create(:user, account: account, role: :agent) }

      before do
        create(:inbox_member, inbox: conversation.inbox, user: agent)
      end

      it 'shows the conversation' do
        get "/api/v1/accounts/#{account.id}/conversations/#{conversation.display_id}/messages",
            headers: agent.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        expect(response).to conform_schema(200)
        expect(JSON.parse(response.body, symbolize_names: true)[:meta][:contact][:id]).to eq(conversation.contact_id)
      end

      it 'answers a canceled database query as a retryable failure' do
        allow(MessageFinder).to receive(:new)
          .and_raise(ActiveRecord::QueryCanceled, 'PG::QueryCanceled: ERROR: canceling statement due to statement timeout')

        get "/api/v1/accounts/#{account.id}/conversations/#{conversation.display_id}/messages",
            headers: agent.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:service_unavailable)
        expect(response.headers['Retry-After']).to match(/\A[1-9]\d*\z/)
        expect(response.parsed_body['error']).to eq(I18n.t('errors.database.query_canceled'))
      end
    end
  end

  describe 'DELETE /api/v1/accounts/{account.id}/conversations/:conversation_id/messages/:id' do
    let(:message) { create(:message, account: account, content_attributes: { bcc_emails: ['hello@chatwoot.com'] }) }
    let(:conversation) { message.conversation }

    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        delete "/api/v1/accounts/#{account.id}/conversations/#{conversation.display_id}/messages/#{message.id}"
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user with access to conversation' do
      let(:agent) { create(:user, account: account, role: :agent) }

      before do
        create(:inbox_member, inbox: conversation.inbox, user: agent)
      end

      it 'deletes the message' do
        delete "/api/v1/accounts/#{account.id}/conversations/#{conversation.display_id}/messages/#{message.id}",
               headers: agent.create_new_auth_token,
               as: :json

        expect(response).to have_http_status(:success)
        expect(message.reload.content).to eq 'This message was deleted'
        expect(message.reload.deleted).to be true
        expect(message.reload.content_attributes['bcc_emails']).to be_nil
      end

      # The provider id reserved before an in-flight send is the only handle on the message once the
      # send response is lost, so the delete must not wipe it along with the rest.
      it 'keeps the reserved provider id while wiping the other content attributes' do
        message.update!(content_attributes: message.content_attributes.merge('pending_source_id' => 'RESERVED_1'))

        delete "/api/v1/accounts/#{account.id}/conversations/#{conversation.display_id}/messages/#{message.id}",
               headers: agent.create_new_auth_token,
               as: :json

        expect(response).to have_http_status(:success)
        expect(message.reload.content_attributes['pending_source_id']).to eq 'RESERVED_1'
        expect(message.content_attributes['bcc_emails']).to be_nil
      end

      it 'keeps the forward marker on a deleted forwarded email' do
        message.update!(content_attributes: { forwarded_message_id: 1, to_emails: ['vendor@example.com'] })

        delete "/api/v1/accounts/#{account.id}/conversations/#{conversation.display_id}/messages/#{message.id}",
               headers: agent.create_new_auth_token,
               as: :json

        expect(message.reload.content_attributes).to eq('forwarded_message_id' => 1, 'deleted' => true)
      end

      it 'deletes interactive messages' do
        interactive_message = create(
          :message, message_type: :outgoing, content: 'test', content_type: 'input_select',
                    content_attributes: { 'items' => [{ 'title' => 'test', 'value' => 'test' }] },
                    conversation: conversation
        )

        delete "/api/v1/accounts/#{account.id}/conversations/#{conversation.display_id}/messages/#{interactive_message.id}",
               headers: agent.create_new_auth_token,
               as: :json

        expect(response).to have_http_status(:success)
        expect(interactive_message.reload.deleted).to be true
      end
    end

    context 'when the message id is invalid' do
      let(:agent) { create(:user, account: account, role: :agent) }

      before do
        create(:inbox_member, inbox: conversation.inbox, user: agent)
      end

      it 'returns not found error' do
        delete "/api/v1/accounts/#{account.id}/conversations/#{conversation.display_id}/messages/99999",
               headers: agent.create_new_auth_token,
               as: :json

        expect(response).to have_http_status(:not_found)
      end
    end

    context 'when channel supports delete_message' do
      let(:whatsapp_channel) { create(:channel_whatsapp, provider: 'baileys', account: account, validate_provider_config: false) }
      let(:whatsapp_inbox) { whatsapp_channel.inbox }
      let(:contact) { create(:contact, account: account, identifier: '+551187654321', phone_number: '+551187654321') }
      let(:contact_inbox) { create(:contact_inbox, inbox: whatsapp_inbox, contact: contact) }
      let(:whatsapp_conversation) { create(:conversation, inbox: whatsapp_inbox, account: account, contact: contact, contact_inbox: contact_inbox) }
      let(:message_with_source) do
        create(:message, account: account, conversation: whatsapp_conversation, inbox: whatsapp_inbox, source_id: 'msg_123', message_type: :outgoing)
      end
      let(:agent) { create(:user, account: account, role: :agent) }
      let(:delete_request_path) { "#{whatsapp_channel.provider_config['provider_url']}/connections/#{whatsapp_channel.phone_number}/messages" }

      before do
        create(:inbox_member, inbox: whatsapp_inbox, user: agent)
      end

      it 'calls delete_message on the channel' do
        delete_stub = stub_request(:delete, delete_request_path)
                      .with(
                        headers: { 'Content-Type' => 'application/json', 'x-api-key' => whatsapp_channel.provider_config['api_key'] },
                        body: hash_including(jid: "#{contact.identifier.delete('+')}@s.whatsapp.net")
                      )
                      .to_return(status: 200, body: '{}')

        perform_enqueued_jobs(only: Messages::DeleteOnChannelJob) do
          delete "/api/v1/accounts/#{account.id}/conversations/#{whatsapp_conversation.display_id}/messages/#{message_with_source.id}",
                 headers: agent.create_new_auth_token,
                 as: :json
        end

        expect(response).to have_http_status(:success)
        expect(message_with_source.reload.deleted).to be true
        expect(delete_stub).to have_been_requested
      end

      it 'does not fail when the provider is unreachable' do
        stub_request(:delete, delete_request_path).to_return(status: 400, body: 'Provider error')

        delete "/api/v1/accounts/#{account.id}/conversations/#{whatsapp_conversation.display_id}/messages/#{message_with_source.id}",
               headers: agent.create_new_auth_token,
               as: :json

        expect(response).to have_http_status(:success)
        expect(message_with_source.reload.deleted).to be true
        # the deletion is retried by the job, so a provider hiccup never fails the agent's request
        expect(Messages::DeleteOnChannelJob).to have_been_enqueued.with(message_with_source.id)
      end

      it 'skips channel deletion when message has no source_id' do
        message_without_source = create(:message, account: account, conversation: whatsapp_conversation, inbox: whatsapp_inbox, source_id: nil)
        delete_stub = stub_request(:delete, delete_request_path).to_return(status: 200, body: '{}')

        perform_enqueued_jobs(only: Messages::DeleteOnChannelJob) do
          delete "/api/v1/accounts/#{account.id}/conversations/#{whatsapp_conversation.display_id}/messages/#{message_without_source.id}",
                 headers: agent.create_new_auth_token,
                 as: :json
        end

        expect(response).to have_http_status(:success)
        expect(message_without_source.reload.deleted).to be true
        expect(delete_stub).not_to have_been_requested
      end
    end

    context 'when channel does not support delete_message' do
      let(:message_with_source) { create(:message, account: account, conversation: conversation, source_id: 'msg_123') }
      let(:agent) { create(:user, account: account, role: :agent) }

      before do
        create(:inbox_member, inbox: conversation.inbox, user: agent)
      end

      it 'skips channel deletion' do
        delete "/api/v1/accounts/#{account.id}/conversations/#{conversation.display_id}/messages/#{message_with_source.id}",
               headers: agent.create_new_auth_token,
               as: :json

        expect(response).to have_http_status(:success)
        expect(message_with_source.reload.deleted).to be true
      end
    end

    context 'when the account blocks agent message deletion' do
      let(:agent) { create(:user, account: account, role: :agent) }
      let(:administrator) { create(:user, account: account, role: :administrator) }

      before do
        create(:inbox_member, inbox: conversation.inbox, user: agent)
        create(:inbox_member, inbox: conversation.inbox, user: administrator)
        account.update!(disable_agent_message_deletion: true)
      end

      it 'refuses the deletion for an agent' do
        delete "/api/v1/accounts/#{account.id}/conversations/#{conversation.display_id}/messages/#{message.id}",
               headers: agent.create_new_auth_token,
               as: :json

        expect(response).to have_http_status(:unauthorized)
        expect(message.reload.deleted).to be_falsey
      end

      it 'still allows an administrator to delete' do
        delete "/api/v1/accounts/#{account.id}/conversations/#{conversation.display_id}/messages/#{message.id}",
               headers: administrator.create_new_auth_token,
               as: :json

        expect(response).to have_http_status(:success)
        expect(message.reload.deleted).to be true
      end
    end
  end

  # Both actions rescue StandardError and hand the exception's own message to the caller, so a
  # bug in the builder answered with a Ruby diagnostic and a missing record answered with the
  # SQL predicate that missed. What the caller can act on has to survive; what only describes
  # our own code must not be echoed.
  describe 'what an error answers to the caller' do
    let!(:inbox) { create(:inbox, account: account) }
    let!(:conversation) { create(:conversation, inbox: inbox, account: account) }
    let(:agent) { create(:user, account: account, role: :agent) }

    before do
      create(:inbox_member, inbox: conversation.inbox, user: agent)
      allow(Rails.logger).to receive(:error)
    end

    def create_message
      post api_v1_account_conversation_messages_url(account_id: account.id, conversation_id: conversation.display_id),
           params: { content: 'test-message' }, headers: agent.create_new_auth_token, as: :json
    end

    context 'when the failure is a bug in our own code' do
      before do
        allow(Messages::MessageBuilder).to receive(:new)
          .and_raise(NoMethodError, "undefined method 'to_h' for an instance of String")
      end

      it 'does not put the Ruby diagnostic in the body' do
        create_message

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.body).not_to include('undefined method')
        expect(response.body).not_to include('an instance of')
      end

      it 'records the real error for whoever has to debug it' do
        create_message

        expect(Rails.logger).to have_received(:error).with(/NoMethodError/)
      end
    end

    # Raised by the builder itself as a plain StandardError, which is indistinguishable from a
    # bug by class alone. The caller can act on it, so it has to keep arriving.
    context 'when the failure is something the caller can act on' do
      before do
        allow(Messages::MessageBuilder).to receive(:new)
          .and_raise(StandardError, 'Incoming messages are only allowed in Api inboxes')
      end

      it 'keeps the message the app chose to raise' do
        create_message

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.parsed_body['error']).to include('Incoming messages are only allowed in Api inboxes')
      end
    end

    context 'when a validation refuses the message' do
      it 'keeps the validation text, which names what to fix' do
        post api_v1_account_conversation_messages_url(account_id: account.id, conversation_id: conversation.display_id),
             params: { content: 'x' * 150_001 }, headers: agent.create_new_auth_token, as: :json

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.body).to include('too long')
      end
    end

    context 'when the message asked for does not exist' do
      it 'answers without the SQL predicate that missed' do
        post "/api/v1/accounts/#{account.id}/conversations/#{conversation.display_id}/messages/999999/retry",
             headers: agent.create_new_auth_token, as: :json

        expect(response.code.to_i).to be_between(400, 499)
        expect(response.body).not_to include("Couldn't find Message")
        expect(response.body).not_to include('[WHERE')
      end
    end
  end

  describe 'POST /api/v1/accounts/{account.id}/conversations/:conversation_id/messages/:id/retry' do
    let(:message) do
      create(:message, account: account, message_type: :outgoing, status: :failed,
                       content_attributes: { external_error: 'error', to_emails: ['vendor@example.com'] })
    end

    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        post "/api/v1/accounts/#{account.id}/conversations/#{message.conversation.display_id}/messages/#{message.id}/retry"
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user with access to conversation' do
      let(:agent) { create(:user, account: account, role: :agent) }

      before do
        create(:inbox_member, inbox: message.conversation.inbox, user: agent)
      end

      it 'retries the message and keeps its delivery details' do
        post "/api/v1/accounts/#{account.id}/conversations/#{message.conversation.display_id}/messages/#{message.id}/retry",
             headers: agent.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:success)
        expect(message.reload.status).to eq('sent')
        expect(message.content_attributes['external_error']).to be_nil
        expect(message.content_attributes['to_emails']).to eq(['vendor@example.com'])
      end

      # The endpoint answering 200 was never the point: what the agent asked for is the message
      # going out again. Nothing here asserted the job, which is how a claim that could never
      # succeed shipped and left Retry clearing the failure marker without resending anything.
      it 'enqueues the send job' do
        clear_enqueued_jobs

        post "/api/v1/accounts/#{account.id}/conversations/#{message.conversation.display_id}/messages/#{message.id}/retry",
             headers: agent.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:success)
        expect(SendReplyJob).to have_been_enqueued.with(message.id)
      end

      it 'enqueues the send job only once when Retry is clicked twice' do
        clear_enqueued_jobs
        2.times do
          post "/api/v1/accounts/#{account.id}/conversations/#{message.conversation.display_id}/messages/#{message.id}/retry",
               headers: agent.create_new_auth_token,
               as: :json
        end

        expect(SendReplyJob).to have_been_enqueued.with(message.id).once
      end

      # On a provider channel the source_id is the provider's receipt, and
      # Base::SendOnChannelService treats a message that has one as already sent by the channel,
      # so a stale id makes the resend skip. The inbox matters here: this used to run on the
      # factory default, which is a web widget, where the send is an email notification and the
      # id belongs to the caller instead.
      it 'clears source_id on a provider channel so the send job does not skip the message' do
        whatsapp_inbox = create(:inbox, account: account, channel: create(:channel_whatsapp, account: account,
                                                                                             validate_provider_config: false, sync_templates: false))
        create(:inbox_member, inbox: whatsapp_inbox, user: agent)
        conversation = create(:conversation, account: account, inbox: whatsapp_inbox)
        failed = create(:message, account: account, conversation: conversation, message_type: :outgoing,
                                  status: :failed, source_id: 'wamid.old_message_id')

        post "/api/v1/accounts/#{account.id}/conversations/#{conversation.display_id}/messages/#{failed.id}/retry",
             headers: agent.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:success)
        expect(failed.reload.source_id).to be_nil
      end
    end

    # An API inbox's source_id is the caller's own identifier for the message, not a provider
    # receipt we are free to discard: clearing it would orphan the reference on their side.
    context 'when the inbox owns its source_id' do
      let(:agent) { create(:user, account: account, role: :agent) }

      %i[api web_widget].each do |channel|
        it "keeps source_id on a #{channel} inbox" do
          inbox = create(:inbox, account: account, channel: create(channel == :api ? :channel_api : :channel_widget, account: account))
          create(:inbox_member, inbox: inbox, user: agent)
          conversation = create(:conversation, account: account, inbox: inbox)
          failed = create(:message, account: account, conversation: conversation, message_type: :outgoing,
                                    status: :failed, source_id: 'caller-owned-id')

          post "/api/v1/accounts/#{account.id}/conversations/#{conversation.display_id}/messages/#{failed.id}/retry",
               headers: agent.create_new_auth_token,
               as: :json

          expect(response).to have_http_status(:success)
          expect(failed.reload.source_id).to eq('caller-owned-id')
        end
      end
    end

    context 'when the message is not failed or not outgoing' do
      let(:agent) { create(:user, account: account, role: :agent) }
      let(:sent_message) { create(:message, account: account, message_type: :outgoing, status: :sent) }
      let(:incoming_failed) { create(:message, account: account, message_type: :incoming, status: :failed) }

      before do
        create(:inbox_member, inbox: sent_message.conversation.inbox, user: agent)
        create(:inbox_member, inbox: incoming_failed.conversation.inbox, user: agent)
      end

      it 'returns unprocessable_entity for non-failed messages' do
        post "/api/v1/accounts/#{account.id}/conversations/#{sent_message.conversation.display_id}/messages/#{sent_message.id}/retry",
             headers: agent.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'returns unprocessable_entity for incoming messages' do
        post "/api/v1/accounts/#{account.id}/conversations/#{incoming_failed.conversation.display_id}/messages/#{incoming_failed.id}/retry",
             headers: agent.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'returns unprocessable_entity for deleted messages' do
        deleted_failed = create(:message, account: account, message_type: :outgoing, status: :failed,
                                          content: 'This message was deleted', content_attributes: { deleted: true })
        create(:inbox_member, inbox: deleted_failed.conversation.inbox, user: agent)
        clear_enqueued_jobs # drop the SendReplyJob queued by the message creation itself

        post "/api/v1/accounts/#{account.id}/conversations/#{deleted_failed.conversation.display_id}/messages/#{deleted_failed.id}/retry",
             headers: agent.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:unprocessable_entity)
        # retrying would wipe content_attributes and push the placeholder to the contact
        expect(deleted_failed.reload).to be_deleted
        expect(SendReplyJob).not_to have_been_enqueued.with(deleted_failed.id)
      end
    end

    context 'when the message id is invalid' do
      let(:agent) { create(:user, account: account, role: :agent) }

      before do
        create(:inbox_member, inbox: message.conversation.inbox, user: agent)
      end

      it 'returns not found error' do
        allow(Rails.logger).to receive(:info)

        post "/api/v1/accounts/#{account.id}/conversations/#{message.conversation.display_id}/messages/99999/retry",
             headers: agent.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:not_found)
        expect(response.parsed_body['error']).to eq('Resource could not be found')
        # the body no longer names the record, so the log is the only place left that does
        expect(Rails.logger).to have_received(:info).with(/Handled error.*RecordNotFound/)
      end
    end
  end

  describe 'PATCH /api/v1/accounts/{account.id}/conversations/:conversation_id/messages/:id' do
    let(:api_channel) { create(:channel_api, account: account) }
    let(:api_inbox) { create(:inbox, channel: api_channel, account: account) }
    let(:agent) { create(:user, account: account, role: :agent) }
    let!(:conversation) { create(:conversation, inbox: api_inbox, account: account) }
    let!(:message) { create(:message, conversation: conversation, account: account, status: :sent) }

    context 'when unauthenticated' do
      it 'returns unauthorized' do
        patch api_v1_account_conversation_message_url(account_id: account.id, conversation_id: conversation.display_id, id: message.id)
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when authenticated agent' do
      context 'when agent has non-API inbox' do
        let(:inbox) { create(:inbox, account: account) }
        let(:agent) { create(:user, account: account, role: :agent) }
        let!(:conversation) { create(:conversation, inbox: inbox, account: account) }

        before { create(:inbox_member, inbox: inbox, user: agent) }

        it 'returns forbidden' do
          patch api_v1_account_conversation_message_url(
            account_id: account.id,
            conversation_id: conversation.display_id,
            id: message.id
          ), params: { status: 'failed', external_error: 'err' }, headers: agent.create_new_auth_token, as: :json
          expect(response).to have_http_status(:forbidden)
        end
      end

      context 'when agent has API inbox' do
        before { create(:inbox_member, inbox: api_inbox, user: agent) }

        it 'uses StatusUpdateService to perform status update' do
          service = instance_double(Messages::StatusUpdateService)
          expect(Messages::StatusUpdateService).to receive(:new)
            .with(message, 'failed', 'err123')
            .and_return(service)
          expect(service).to receive(:perform)
          patch api_v1_account_conversation_message_url(
            account_id: account.id,
            conversation_id: conversation.display_id,
            id: message.id
          ), params: { status: 'failed', external_error: 'err123' }, headers: agent.create_new_auth_token, as: :json
        end

        it 'updates status to failed with external_error' do
          patch api_v1_account_conversation_message_url(
            account_id: account.id,
            conversation_id: conversation.display_id,
            id: message.id
          ), params: { status: 'failed', external_error: 'err123' }, headers: agent.create_new_auth_token, as: :json

          expect(response).to have_http_status(:success)
          expect(message.reload.status).to eq('failed')
          expect(message.reload.external_error).to eq('err123')
        end
      end
    end
  end

  # The edit an agent types is written before the channel has taken it, and written back when the channel
  # refuses. Only the edit the channel accepted is an edit anybody made (fazer-ai/chatwoot#648).
  describe 'PATCH /api/v1/accounts/{account.id}/conversations/:conversation_id/messages/:id/edit_content' do
    let(:channel) { create(:channel_whatsapp, account: account, provider: 'native', validate_provider_config: false, sync_templates: false) }
    let(:inbox) { channel.inbox }
    let(:agent) { create(:user, account: account, role: :agent) }
    let!(:conversation) { create(:conversation, inbox: inbox, account: account) }
    let!(:message) do
      create(:message, conversation: conversation, account: account, inbox: inbox,
                       message_type: :outgoing, content: 'preço sob consulta', source_id: 'WAMID.1')
    end

    before do
      create(:inbox_member, inbox: inbox, user: agent)
      allow(Rails.configuration.dispatcher).to receive(:dispatch).and_call_original
    end

    def edit(content)
      patch edit_content_api_v1_account_conversation_message_url(
        account_id: account.id, conversation_id: conversation.display_id, id: message.id
      ), params: { content: content }, headers: agent.create_new_auth_token, as: :json
    end

    it 'announces the edit once the channel has taken it' do
      allow_any_instance_of(Channel::Whatsapp).to receive(:edit_message).and_return(true) # rubocop:disable RSpec/AnyInstance

      edit('orçamento em 24h')

      expect(response).to have_http_status(:success)
      expect(Rails.configuration.dispatcher).to have_received(:dispatch)
        .with(Events::Types::MESSAGE_EDITED, anything, anything).once
    end

    # The body the contact has is still the original one, and the controller has already written the new
    # one and then written it back. Neither of those two commits is an edit anybody made.
    it 'announces nothing when the channel refuses the edit' do
      allow_any_instance_of(Channel::Whatsapp).to receive(:edit_message).and_raise(StandardError, 'channel refused') # rubocop:disable RSpec/AnyInstance

      edit('orçamento em 24h')

      expect(message.reload.content).to eq('preço sob consulta')
      expect(Rails.configuration.dispatcher).not_to have_received(:dispatch)
        .with(Events::Types::MESSAGE_EDITED, anything, anything)
    end

    # The write is optimistic, so between it and the channel's answer the row shows a body the contact
    # may never receive. An evaluation queued by an earlier edit reads the row when it runs, not when it
    # was announced, and would answer about that body (fazer-ai/chatwoot#660).
    context 'with rules waiting on an edit of their own' do
      include ActiveJob::TestHelper

      let!(:on_orcamento) { edit_rule('ED_ORC', 'orçamento') }
      let!(:on_desconto) { edit_rule('ED_DESCONTO', 'desconto') }

      def edit_rule(name, word)
        create(:automation_rule, account: account, name: name, event_name: 'message_edited',
                                 conditions: [{ 'attribute_key' => 'content', 'filter_operator' => 'contains',
                                                'values' => [word], 'query_operator' => nil }],
                                 actions: [{ 'action_name' => 'send_message', 'action_params' => [name] }])
      end

      def ran(automation_rule)
        account.messages.where("((content_attributes#>>'{}')::jsonb)->>'automation_rule_id' = ?", automation_rule.id.to_s).count
      end

      # Everything but the avatar fetch, which the agent and the contact queue on creation and which
      # would go out to gravatar from inside the example.
      def drain
        perform_enqueued_jobs(except: Avatar::AvatarFromUrlJob)
      end

      # The refusal is made to land while the queued work is running, which is the whole window the issue
      # is about: the first edit's evaluation reaches the row with the second edit's body on it.
      it 'keeps a queued evaluation off the refused body, and announces the body it put back' do
        accepted = true
        allow_any_instance_of(Channel::Whatsapp).to receive(:edit_message) do # rubocop:disable RSpec/AnyInstance
          next true if accepted

          drain
          raise StandardError, 'channel refused'
        end

        edit('orçamento em 24h')
        accepted = false
        edit('desconto de 30%')
        drain

        expect(ran(on_desconto)).to eq(0)
        expect(ran(on_orcamento)).to eq(1)
        expect(message.reload.content).to eq('orçamento em 24h')
        expect(message.reload.is_edited).to be(true)
      end
    end
  end

  describe 'POST /api/v1/accounts/{account.id}/conversations/:conversation_id/messages/:id/fetch_media' do
    let(:channel) { create(:channel_whatsapp, account: account, provider: 'native', validate_provider_config: false, sync_templates: false) }
    let(:conversation) { create(:conversation, account: account, inbox: channel.inbox) }
    let(:admin) { create(:user, account: account, role: :administrator) }
    let(:pending_media) { Whatsapp::Session::Model::Content::Media.new(kind: 'image', mime: 'image/jpeg').to_h }
    let(:message) do
      create(:message, conversation: conversation, inbox: channel.inbox, account: account, source_id: 'HIST1',
                       content_attributes: { 'is_unsupported' => true, 'history_media' => true, 'pending_media' => pending_media })
    end
    let(:url) { "/api/v1/accounts/#{account.id}/conversations/#{conversation.display_id}/messages/#{message.id}/fetch_media" }

    it 'queues the download of a history file that is still missing' do
      expect do
        post url, headers: admin.create_new_auth_token, as: :json
      end.to have_enqueued_job(Whatsapp::Session::MediaFetchJob).with(message, pending_media, anything)

      expect(response).to have_http_status(:accepted)
    end

    it 'refuses a message that is not a missing history file' do
      message.update!(content_attributes: {})

      expect do
        post url, headers: admin.create_new_auth_token, as: :json
      end.not_to have_enqueued_job(Whatsapp::Session::MediaFetchJob)

      expect(response).to have_http_status(:unprocessable_entity)
    end

    it 'refuses a history file that has already arrived' do
      message.attachments.create!(account: account, file_type: :fallback, fallback_title: 'foto')

      expect do
        post url, headers: admin.create_new_auth_token, as: :json
      end.not_to have_enqueued_job(Whatsapp::Session::MediaFetchJob)

      expect(response).to have_http_status(:unprocessable_entity)
    end

    it 'refuses an agent who cannot see the inbox' do
      agent = create(:user, account: account, role: :agent)

      expect do
        post url, headers: agent.create_new_auth_token, as: :json
      end.not_to have_enqueued_job(Whatsapp::Session::MediaFetchJob)

      expect(response).to have_http_status(:unauthorized)
    end

    # The messages API stores whatever content_attributes a client sends, so the marks of a
    # history file are not proof that one is waiting: a descriptor an agent wrote would have
    # the provider download any URL with the connector's token.
    # An activity written through the API has no sender, like a message sent from the phone,
    # which is why the author alone is not enough either.
    %w[outgoing activity].each do |message_type|
      it "refuses #{message_type} message an agent wrote with the marks of a history file" do
        forged = { 'is_unsupported' => true, 'history_media' => true, 'imported' => true,
                   'pending_media' => pending_media.merge('ref' => { 'kind' => 'url', 'url' => 'http://169.254.169.254/latest' }) }
        post "/api/v1/accounts/#{account.id}/conversations/#{conversation.display_id}/messages",
             params: { content: 'x', message_type: message_type, content_attributes: forged }, headers: admin.create_new_auth_token, as: :json
        written = conversation.messages.find(response.parsed_body['id'])
        # Set afterwards, as if a client could still get them in: provenance has to hold alone.
        expect(written.content_attributes).not_to include('history_media', 'pending_media')
        written.update!(content_attributes: written.content_attributes.merge(forged), source_id: 'FAKE1')

        expect do
          post "/api/v1/accounts/#{account.id}/conversations/#{conversation.display_id}/messages/#{written.id}/fetch_media",
               headers: admin.create_new_auth_token, as: :json
        end.not_to have_enqueued_job(Whatsapp::Session::MediaFetchJob)

        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    # An author deleted later leaves the message with no sender, which is what a message sent
    # from the phone looks like: the marks must never get in from a client to begin with.
    it 'drops the history marks a client sends with a new message' do
      sent = { 'history_media' => true, 'imported' => true, 'pending_media' => pending_media, 'in_reply_to' => message.id }
      post "/api/v1/accounts/#{account.id}/conversations/#{conversation.display_id}/messages",
           params: { content: 'x', source_id: 'FAKE2', content_attributes: sent }, headers: admin.create_new_auth_token, as: :json

      written = conversation.messages.find(response.parsed_body['id'])
      expect(written.content_attributes).not_to include('history_media', 'imported', 'pending_media')
      expect(written.content_attributes['in_reply_to']).to eq(message.id)
    end

    it 'answers not found for a message of another conversation' do
      other = create(:message, account: account)

      post "/api/v1/accounts/#{account.id}/conversations/#{conversation.display_id}/messages/#{other.id}/fetch_media",
           headers: admin.create_new_auth_token, as: :json

      expect(response).to have_http_status(:not_found)
    end
  end
end
