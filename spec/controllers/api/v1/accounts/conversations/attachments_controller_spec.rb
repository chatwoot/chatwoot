require 'rails_helper'

RSpec.describe 'Conversation Message Attachments API', type: :request do
  let!(:account) { create(:account) }
  let!(:inbox) { create(:inbox, account: account) }
  let!(:conversation) { create(:conversation, inbox: inbox, account: account) }
  let!(:message) { create(:message, conversation: conversation, account: account) }
  let!(:attachment) { message.attachments.create!(account: account, file_type: :fallback, fallback_title: 'Test attachment') }

  describe 'PATCH /api/v1/accounts/{account.id}/conversations/{conversation_id}/messages/{message_id}/attachments/{id}' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        patch api_v1_account_conversation_message_attachment_url(
          account_id: account.id,
          conversation_id: conversation.display_id,
          message_id: message.id,
          id: attachment.id
        )

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user with access to conversation' do
      let(:agent) { create(:user, account: account, role: :agent) }

      before do
        create(:inbox_member, inbox: conversation.inbox, user: agent)
      end

      it 'updates attachment meta' do
        params = { meta: { description: 'Audio recording from meeting', source: 'microphone' } }

        patch api_v1_account_conversation_message_attachment_url(
          account_id: account.id,
          conversation_id: conversation.display_id,
          message_id: message.id,
          id: attachment.id
        ),
              params: params,
              headers: agent.create_new_auth_token,
              as: :json

        expect(response).to have_http_status(:success)
        expect(attachment.reload.meta).to eq({ 'description' => 'Audio recording from meeting', 'source' => 'microphone' })
      end

      it 'returns the updated attachment data' do
        params = { meta: { description: 'Test attachment' } }

        patch api_v1_account_conversation_message_attachment_url(
          account_id: account.id,
          conversation_id: conversation.display_id,
          message_id: message.id,
          id: attachment.id
        ),
              params: params,
              headers: agent.create_new_auth_token,
              as: :json

        expect(response).to have_http_status(:success)
        response_data = response.parsed_body
        expect(response_data['id']).to eq(attachment.id)
        expect(response_data['meta']).to eq({ 'description' => 'Test attachment' })
      end

      it 'triggers message update event' do
        params = { meta: { description: 'Updated description' } }

        allow(Rails.configuration.dispatcher).to receive(:dispatch)

        patch api_v1_account_conversation_message_attachment_url(
          account_id: account.id,
          conversation_id: conversation.display_id,
          message_id: message.id,
          id: attachment.id
        ),
              params: params,
              headers: agent.create_new_auth_token,
              as: :json

        expect(response).to have_http_status(:success)
        expect(Rails.configuration.dispatcher).to have_received(:dispatch).with(
          'message.updated', anything, hash_including(message: an_instance_of(Message))
        )
      end

      it 'handles request without meta parameter' do
        patch api_v1_account_conversation_message_attachment_url(
          account_id: account.id,
          conversation_id: conversation.display_id,
          message_id: message.id,
          id: attachment.id
        ),
              params: {},
              headers: agent.create_new_auth_token,
              as: :json

        expect(response).to have_http_status(:success)
        expect(attachment.reload.meta).to eq({})
      end

      it 'handles empty meta parameter' do
        attachment.update!(meta: { existing: 'data' })

        patch api_v1_account_conversation_message_attachment_url(
          account_id: account.id,
          conversation_id: conversation.display_id,
          message_id: message.id,
          id: attachment.id
        ),
              params: { meta: {} },
              headers: agent.create_new_auth_token,
              as: :json

        expect(response).to have_http_status(:success)
        expect(attachment.reload.meta).to eq({})
      end

      it 'rejects metadata that exceeds size limit' do
        large_value = 'x' * 17_000
        params = { meta: { large_field: large_value } }

        patch api_v1_account_conversation_message_attachment_url(
          account_id: account.id,
          conversation_id: conversation.display_id,
          message_id: message.id,
          id: attachment.id
        ),
              params: params,
              headers: agent.create_new_auth_token,
              as: :json

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.parsed_body['error']).to include('Metadata size exceeds maximum')
      end

      it 'returns not found for non-existent attachment' do
        patch api_v1_account_conversation_message_attachment_url(
          account_id: account.id,
          conversation_id: conversation.display_id,
          message_id: message.id,
          id: 0
        ),
              params: { meta: { key: 'value' } },
              headers: agent.create_new_auth_token,
              as: :json

        expect(response).to have_http_status(:not_found)
      end

      it 'returns not found for non-existent message' do
        patch api_v1_account_conversation_message_attachment_url(
          account_id: account.id,
          conversation_id: conversation.display_id,
          message_id: 0,
          id: attachment.id
        ),
              params: { meta: { key: 'value' } },
              headers: agent.create_new_auth_token,
              as: :json

        expect(response).to have_http_status(:not_found)
      end
    end

    context 'when it is an authenticated user without access to conversation' do
      let(:agent) { create(:user, account: account, role: :agent) }

      it 'returns unauthorized' do
        params = { meta: { description: 'Test' } }

        patch api_v1_account_conversation_message_attachment_url(
          account_id: account.id,
          conversation_id: conversation.display_id,
          message_id: message.id,
          id: attachment.id
        ),
              params: params,
              headers: agent.create_new_auth_token,
              as: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end
