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

      context 'with an eligible WhatsApp Cloud conversation' do
        let(:whatsapp_channel) do
          create(
            :channel_whatsapp,
            account: account,
            provider: 'whatsapp_cloud',
            validate_provider_config: false,
            sync_templates: false
          )
        end
        let(:inbox) { whatsapp_channel.inbox }
        let(:contact) { create(:contact, account: account, phone_number: '+15550000001') }
        let(:contact_inbox) { create(:contact_inbox, inbox: inbox, contact: contact, source_id: '15550000001') }
        let(:conversation) { create(:conversation, inbox: inbox, account: account, contact_inbox: contact_inbox) }

        before do
          account.enable_features!(*Whatsapp::InteractiveMessages::Eligibility::TYPE_FEATURES.values)
          create(:message, :incoming, conversation: conversation, account: account, inbox: inbox)
        end

        it 'returns the server-resolved interactive snapshot from message creation' do
          params = {
            content_attributes: {
              whatsapp_interactive: {
                schema_version: 1,
                type: 'button',
                body: { text: 'Please choose one option.' },
                action: { buttons: [{ title: 'Confirm' }, { title: 'Change' }] }
              }
            }
          }

          with_modified_env Whatsapp::InteractiveMessages::Eligibility::TEST_ALLOWLIST_ENV => '+15550000001,+15550000002' do
            post api_v1_account_conversation_messages_url(account_id: account.id, conversation_id: conversation.display_id),
                 params: params,
                 headers: agent.create_new_auth_token,
                 as: :json
          end

          expect(response).to have_http_status(:success)
          snapshot = response.parsed_body.dig('content_attributes', 'whatsapp_interactive')
          persisted_snapshot = conversation.messages.outgoing.last.content_attributes['whatsapp_interactive']

          expect(snapshot).to eq(persisted_snapshot)
          expect(snapshot.except('action')).to eq(
            'schema_version' => 1,
            'type' => 'button',
            'body' => { 'text' => 'Please choose one option.' }
          )
          expect(snapshot.dig('action', 'buttons').pluck('title')).to eq(%w[Confirm Change])
          expect(snapshot.dig('action', 'buttons').pluck('delivery_id')).to all(start_with('reply_'))
        end

        it 'returns a resolved media header through the existing multipart message upload path' do
          interactive = {
            schema_version: 1, type: 'button', header: { type: 'image' }, footer: { text: 'Footer' },
            body: { text: 'Choose' }, action: { buttons: [{ title: 'Confirm' }] }
          }
          upload = Rack::Test::UploadedFile.new(Rails.root.join('spec/assets/avatar.png'), 'image/png')

          with_modified_env Whatsapp::InteractiveMessages::Eligibility::TEST_ALLOWLIST_ENV => '+15550000001,+15550000002' do
            post api_v1_account_conversation_messages_url(account_id: account.id, conversation_id: conversation.display_id),
                 params: { content_attributes: { whatsapp_interactive: interactive }.to_json, attachments: [upload] },
                 headers: agent.create_new_auth_token
          end

          expect(response).to have_http_status(:success)
          message = conversation.messages.outgoing.last
          expect(response.parsed_body.dig('content_attributes', 'whatsapp_interactive', 'header')).to eq(
            'type' => 'image', 'attachment_id' => message.attachments.sole.id
          )
          expect(message.content_attributes.dig('whatsapp_interactive', 'footer', 'text')).to eq('Footer')
        end
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

        expect(response).to have_http_status(:unprocessable_entity)
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
        select_item1 = build(:bot_message_select)
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
  end

  describe 'POST /api/v1/accounts/{account.id}/conversations/:conversation_id/messages/:id/retry' do
    let(:message) { create(:message, account: account, status: :failed, content_attributes: { external_error: 'error' }) }

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

      it 'retries the message' do
        post "/api/v1/accounts/#{account.id}/conversations/#{message.conversation.display_id}/messages/#{message.id}/retry",
             headers: agent.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:success)
        expect(message.reload.status).to eq('sent')
        expect(message.reload.content_attributes['external_error']).to be_nil
      end

      it 'keeps the generic retry path when a non-Cloud message has interactive-shaped metadata' do
        message.update!(content_attributes: {
                          external_error: 'error',
                          whatsapp_interactive: { type: 'button' }
                        })

        post "/api/v1/accounts/#{account.id}/conversations/#{message.conversation.display_id}/messages/#{message.id}/retry",
             headers: agent.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:success)
        expect(message.reload).to have_attributes(status: 'sent', content_attributes: {})
      end
    end

    context 'when the message id is invalid' do
      let(:agent) { create(:user, account: account, role: :agent) }

      before do
        create(:inbox_member, inbox: message.conversation.inbox, user: agent)
      end

      it 'returns not found error' do
        post "/api/v1/accounts/#{account.id}/conversations/#{message.conversation.display_id}/messages/99999/retry",
             headers: agent.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context 'with a failed normalized WhatsApp Cloud interaction' do
      let(:whatsapp_channel) do
        create(
          :channel_whatsapp,
          account: account,
          provider: 'whatsapp_cloud',
          validate_provider_config: false,
          sync_templates: false
        )
      end
      let(:conversation) { create(:conversation, account: account, inbox: whatsapp_channel.inbox) }
      let(:snapshot) { JSON.parse(Rails.root.join('spec/fixtures/whatsapp_interactive_messages/button.json').read) }
      let(:message) do
        create(
          :message,
          account: account,
          inbox: whatsapp_channel.inbox,
          conversation: conversation,
          message_type: :outgoing,
          status: :failed,
          source_id: 'wamid.superseded',
          content_attributes: {
            external_error: 'old provider error',
            whatsapp_interactive: snapshot,
            whatsapp_delivery: {
              retry_count: 2,
              provider_error: { code: 131_000, reason: 'Old provider reason' }
            },
            custom_metadata: { preserved: true }
          }
        )
      end
      let(:agent) { create(:user, account: account, role: :agent) }

      before do
        create(:inbox_member, inbox: conversation.inbox, user: agent)
        message.attachments.create!(
          account_id: account.id,
          file_type: :image,
          file: Rack::Test::UploadedFile.new(Rails.root.join('spec/assets/avatar.png'), 'image/png')
        )
      end

      it 'claims the same message once while preserving its snapshot, errors, metadata, and attachments' do
        original_snapshot = message.content_attributes['whatsapp_interactive'].deep_dup
        original_attachment_ids = message.attachments.ids

        expect do
          post "/api/v1/accounts/#{account.id}/conversations/#{conversation.display_id}/messages/#{message.id}/retry",
               headers: agent.create_new_auth_token,
               as: :json
        end.to have_enqueued_job(SendReplyJob).with(message.id).once

        expect(response).to have_http_status(:success)
        expect(message.reload).to have_attributes(status: 'pending', source_id: nil, external_error: 'old provider error')
        expect(message.content_attributes).to include(
          'whatsapp_interactive' => original_snapshot,
          'whatsapp_delivery' => {
            'retry_count' => 3,
            'provider_error' => { 'code' => 131_000, 'reason' => 'Old provider reason' }
          },
          'custom_metadata' => { 'preserved' => true }
        )
        expect(message.attachments.ids).to eq(original_attachment_ids)
        expect(conversation.messages.where(id: message.id).count).to eq(1)
      end

      it 'rejects a duplicate retry without enqueueing a second send' do
        Whatsapp::InteractiveMessages::RetryService.new(message).perform

        expect do
          post "/api/v1/accounts/#{account.id}/conversations/#{conversation.display_id}/messages/#{message.id}/retry",
               headers: agent.create_new_auth_token,
               as: :json
        end.not_to have_enqueued_job(SendReplyJob)

        expect(response).to have_http_status(:unprocessable_entity)
        expect(message.reload.content_attributes.dig('whatsapp_delivery', 'retry_count')).to eq(3)
      end

      it 'restores the exact failed state when enqueueing raises' do
        original_attributes = message.content_attributes.deep_dup
        allow(SendReplyJob).to receive(:perform_later).with(message.id).and_raise(ActiveJob::EnqueueError, 'queue unavailable')

        post "/api/v1/accounts/#{account.id}/conversations/#{conversation.display_id}/messages/#{message.id}/retry",
             headers: agent.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:unprocessable_entity)
        expect(message.reload).to have_attributes(status: 'failed', source_id: 'wamid.superseded')
        expect(message.content_attributes).to eq(original_attributes)
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
end
