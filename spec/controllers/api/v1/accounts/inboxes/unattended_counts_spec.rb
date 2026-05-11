require 'rails_helper'

RSpec.describe 'Inbox unattended counts API', type: :request do
  let(:account) { create(:account) }
  let(:agent) { create(:user, account: account, role: :agent) }
  let(:inbox) { create(:inbox, account: account) }
  let(:other_inbox) { create(:inbox, account: account) }

  describe 'GET /api/v1/accounts/{account.id}/inboxes/unattended_counts' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get "/api/v1/accounts/#{account.id}/inboxes/unattended_counts"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      before do
        create(:inbox_member, user: agent, inbox: inbox)
      end

      it 'returns conversations with unread incoming messages grouped by accessible inbox' do
        conversation_with_multiple_unread_messages = create(:conversation, account: account, inbox: inbox, agent_last_seen_at: 1.hour.ago)
        create(:message, account: account, inbox: inbox, conversation: conversation_with_multiple_unread_messages, message_type: :incoming)
        create(:message, account: account, inbox: inbox, conversation: conversation_with_multiple_unread_messages, message_type: :incoming)

        conversation_with_one_unread_message = create(:conversation, account: account, inbox: inbox, agent_last_seen_at: 1.hour.ago)
        create(:message, account: account, inbox: inbox, conversation: conversation_with_one_unread_message, message_type: :incoming)

        read_conversation = create(:conversation, account: account, inbox: inbox, agent_last_seen_at: Time.current)
        create(:message, account: account, inbox: inbox, conversation: read_conversation, message_type: :incoming, created_at: 1.hour.ago)

        inaccessible_conversation = create(:conversation, account: account, inbox: other_inbox, agent_last_seen_at: nil)
        create(:message, account: account, inbox: other_inbox, conversation: inaccessible_conversation, message_type: :incoming)

        get "/api/v1/accounts/#{account.id}/inboxes/unattended_counts",
            headers: agent.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)

        payload = response.parsed_body['payload']
        expect(payload[inbox.id.to_s]).to eq(2)
        expect(payload).not_to have_key(other_inbox.id.to_s)
      end
    end
  end
end
