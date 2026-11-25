require 'rails_helper'

RSpec.describe 'Conversation Message Reactions API', type: :request do
  let(:account) { create(:account) }
  let(:agent) { create(:user, account: account, role: :agent) }
  let(:other_agent) { create(:user, account: account, role: :agent) }
  let(:channel) { create(:channel_whatsapp, account: account, provider: 'baileys', validate_provider_config: false, sync_templates: false) }
  let(:inbox) { channel.inbox }
  let(:conversation) { create(:conversation, account: account, inbox: inbox) }
  let!(:target_message) { create(:message, account: account, conversation: conversation, content: 'Hi', source_id: 'wamid.target') }
  let(:reactions_url) do
    "/api/v1/accounts/#{account.id}/conversations/#{conversation.display_id}/messages/#{target_message.id}/reactions"
  end

  before do
    create(:inbox_member, inbox: inbox, user: agent)
    create(:inbox_member, inbox: inbox, user: other_agent)
    # Provider would be invoked by SendReplyJob; stub the actual send.
    allow_any_instance_of(Whatsapp::Providers::WhatsappBaileysService).to receive(:send_message).and_return('msg_id') # rubocop:disable RSpec/AnyInstance
  end

  describe 'POST /api/v1/accounts/:account_id/conversations/:conversation_id/messages/:message_id/reactions' do
    context 'when the request is unauthenticated' do
      it 'returns unauthorized' do
        post reactions_url, params: { emoji: '👍' }, as: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when the channel does not support reactions' do
      let(:channel) { create(:channel_whatsapp, account: account, provider: 'default', validate_provider_config: false, sync_templates: false) }

      it 'rejects the request with unprocessable_entity' do
        post reactions_url, params: { emoji: '👍' }, headers: agent.create_new_auth_token, as: :json

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.parsed_body['error']).to match(/not supported/i)
      end
    end

    context 'when the target message is a private note' do
      let!(:target_message) { create(:message, account: account, conversation: conversation, content: 'Note', private: true) }

      it 'allows the reaction and creates a private reaction Message' do
        expect do
          post reactions_url, params: { emoji: '👍' }, headers: agent.create_new_auth_token, as: :json
        end.to change(conversation.messages, :count).by(1)

        expect(response).to have_http_status(:ok)
        created = conversation.messages.last
        expect(created.private).to be true
        expect(created.content).to eq('👍')
        expect(created.content_attributes['is_reaction']).to be true
        expect(created.content_attributes['in_reply_to']).to eq(target_message.id)
      end

      context 'when the inbox channel does not support reactions' do
        let(:channel) { create(:channel_whatsapp, account: account, provider: 'default', validate_provider_config: false, sync_templates: false) }

        it 'still allows reacting to the private note' do
          post reactions_url, params: { emoji: '👍' }, headers: agent.create_new_auth_token, as: :json

          expect(response).to have_http_status(:ok)
        end
      end

      it 'does not dispatch the reaction to the external provider' do
        expect_any_instance_of(Whatsapp::Providers::WhatsappBaileysService).not_to receive(:send_message) # rubocop:disable RSpec/AnyInstance

        perform_enqueued_jobs do
          post reactions_url, params: { emoji: '👍' }, headers: agent.create_new_auth_token, as: :json
        end

        expect(response).to have_http_status(:ok)
      end
    end

    context 'when the target message is itself a reaction' do
      let(:target_message) do
        create(:message,
               account: account,
               conversation: conversation,
               content: '👍',
               content_attributes: { is_reaction: true })
      end

      it 'rejects the request' do
        post reactions_url, params: { emoji: '🔥' }, headers: agent.create_new_auth_token, as: :json

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.parsed_body['error']).to match(/reaction/i)
      end
    end

    context 'when the emoji exceeds 32 bytes' do
      it 'rejects the request' do
        post reactions_url, params: { emoji: 'a' * 64 }, headers: agent.create_new_auth_token, as: :json

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.parsed_body['error']).to match(/Invalid emoji/i)
      end
    end

    context 'when no current-user reaction exists' do
      it 'creates a new reaction Message via MessageBuilder' do
        expect do
          post reactions_url, params: { emoji: '👍' }, headers: agent.create_new_auth_token, as: :json
        end.to change(conversation.messages, :count).by(1)

        expect(response).to have_http_status(:ok)
        created = conversation.messages.last
        expect(created.content).to eq('👍')
        expect(created.content_attributes['is_reaction']).to be true
        expect(created.content_attributes['in_reply_to']).to eq(target_message.id)
        expect(created.sender).to eq(agent)
      end

      it 'rejects an empty emoji when there is nothing to remove' do
        post reactions_url, params: { emoji: '' }, headers: agent.create_new_auth_token, as: :json

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.parsed_body['error']).to match(/empty/i)
      end
    end

    context 'when the current user already has an active reaction' do
      let!(:existing) do
        create(:message,
               account: account,
               conversation: conversation,
               sender: agent,
               message_type: :outgoing,
               content: '👍',
               source_id: 'wa_existing_id',
               content_attributes: { is_reaction: true, in_reply_to: target_message.id })
      end

      it 'toggles off when the same emoji is sent (mutates row, sets deleted, clears source_id)' do
        post reactions_url, params: { emoji: '👍' }, headers: agent.create_new_auth_token, as: :json

        expect(response).to have_http_status(:ok)
        existing.reload
        expect(existing.content).to eq('')
        expect(existing.content_attributes['deleted']).to be true
        expect(existing.source_id).to be_nil
      end

      it 'toggles off when an empty emoji is sent' do
        post reactions_url, params: { emoji: '' }, headers: agent.create_new_auth_token, as: :json

        expect(response).to have_http_status(:ok)
        existing.reload
        expect(existing.content).to eq('')
        expect(existing.content_attributes['deleted']).to be true
      end

      it 'replaces in place when a different emoji is sent (does not create a new row)' do
        expect do
          post reactions_url, params: { emoji: '❤️' }, headers: agent.create_new_auth_token, as: :json
        end.not_to change(conversation.messages, :count)

        existing.reload
        expect(existing.content).to eq('❤️')
        expect(existing.content_attributes['deleted']).to be_nil.or(be(false))
        expect(existing.source_id).to be_nil
      end

      # The row is about to be sent again, so it must not reuse the WhatsApp id reserved for the
      # previous reaction — the resend would be seen as that same message.
      it 'drops the reserved provider id so the resend gets a fresh one' do
        existing.update!(content_attributes: existing.content_attributes.merge('pending_source_id' => 'RESERVED_1'))

        post reactions_url, params: { emoji: '❤️' }, headers: agent.create_new_auth_token, as: :json

        expect(existing.reload.content_attributes['pending_source_id']).to be_nil
      end

      it 'enqueues SendReplyJob with the existing message id when toggling off' do
        expect do
          post reactions_url, params: { emoji: '👍' }, headers: agent.create_new_auth_token, as: :json
        end.to have_enqueued_job(SendReplyJob).with(existing.id)
      end
    end

    context 'when the current user previously removed their reaction' do
      let!(:existing) do
        create(:message,
               account: account,
               conversation: conversation,
               sender: agent,
               message_type: :outgoing,
               content: '',
               content_attributes: { is_reaction: true, in_reply_to: target_message.id, deleted: true })
      end

      it 'resurrects the row instead of creating a new one' do
        expect do
          post reactions_url, params: { emoji: '🔥' }, headers: agent.create_new_auth_token, as: :json
        end.not_to change(conversation.messages, :count)

        existing.reload
        expect(existing.content).to eq('🔥')
        expect(existing.content_attributes).not_to have_key('deleted')
      end
    end

    context 'when only a reaction from another agent exists' do
      let!(:other_agent_reaction) do
        create(:message,
               account: account,
               conversation: conversation,
               sender: other_agent,
               message_type: :outgoing,
               content: '👍',
               content_attributes: { is_reaction: true, in_reply_to: target_message.id })
      end

      it 'creates a separate reaction Message scoped to the current user' do
        expect do
          post reactions_url, params: { emoji: '🎉' }, headers: agent.create_new_auth_token, as: :json
        end.to change(conversation.messages, :count).by(1)

        expect(other_agent_reaction.reload.content).to eq('👍')
        new_reaction = conversation.messages.where(sender: agent).last
        expect(new_reaction.content).to eq('🎉')
      end
    end

    context 'when only a multi-device echo (outgoing without agent) exists' do
      let!(:multi_device_reaction) do
        create(:message, :bot_message,
               account: account,
               conversation: conversation,
               content: '👍',
               source_id: 'wa_mobile_id',
               content_attributes: { is_reaction: true, in_reply_to: target_message.id })
      end

      it 'mutates the multi-device echo when the same emoji is sent (toggle off)' do
        expect do
          post reactions_url, params: { emoji: '👍' }, headers: agent.create_new_auth_token, as: :json
        end.not_to change(conversation.messages, :count)

        multi_device_reaction.reload
        expect(multi_device_reaction.content).to eq('')
        expect(multi_device_reaction.content_attributes['deleted']).to be true
        expect(multi_device_reaction.source_id).to be_nil
      end

      it 'mutates the multi-device echo when a different emoji is sent (replace)' do
        expect do
          post reactions_url, params: { emoji: '❤️' }, headers: agent.create_new_auth_token, as: :json
        end.not_to change(conversation.messages, :count)

        multi_device_reaction.reload
        expect(multi_device_reaction.content).to eq('❤️')
      end

      it 'enqueues SendReplyJob to propagate the change to WhatsApp' do
        expect do
          post reactions_url, params: { emoji: '👍' }, headers: agent.create_new_auth_token, as: :json
        end.to have_enqueued_job(SendReplyJob).with(multi_device_reaction.id)
      end
    end

    context 'when a current-user reaction and a multi-device echo both exist' do
      let!(:multi_device_reaction) do
        create(:message, :bot_message,
               account: account,
               conversation: conversation,
               content: '👍',
               created_at: 2.minutes.ago,
               content_attributes: { is_reaction: true, in_reply_to: target_message.id })
      end
      let!(:user_reaction) do
        create(:message,
               account: account,
               conversation: conversation,
               sender: agent,
               message_type: :outgoing,
               content: '🔥',
               created_at: 1.minute.ago,
               content_attributes: { is_reaction: true, in_reply_to: target_message.id })
      end

      it 'prefers the most recent qualifying reaction (current user, not multi-device)' do
        post reactions_url, params: { emoji: '🔥' }, headers: agent.create_new_auth_token, as: :json

        user_reaction.reload
        expect(user_reaction.content).to eq('')
        expect(user_reaction.content_attributes['deleted']).to be true
        expect(multi_device_reaction.reload.content).to eq('👍')
      end
    end

    context 'with side effects on the conversation snapshot' do
      it 'touches the conversation updated_at so the chat list re-fetches the snapshot' do
        original_updated_at = conversation.updated_at

        travel(1.minute) do
          post reactions_url, params: { emoji: '👍' }, headers: agent.create_new_auth_token, as: :json
        end

        expect(conversation.reload.updated_at).to be > original_updated_at
      end

      it 'dispatches conversation.updated so cable subscribers refresh last_non_activity_message' do
        dispatch_calls = []
        allow_any_instance_of(Conversation).to receive(:dispatch_conversation_updated_event) do |conv| # rubocop:disable RSpec/AnyInstance
          dispatch_calls << conv.id
        end

        post reactions_url, params: { emoji: '👍' }, headers: agent.create_new_auth_token, as: :json

        expect(dispatch_calls).to include(conversation.id)
      end
    end
  end
end
