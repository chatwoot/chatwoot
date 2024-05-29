require 'rails_helper'

RSpec.describe 'Conversation Draft Messages API', type: :request do
  let(:account) { create(:account) }

  describe 'POST /api/v1/accounts/{account.id}/conversations/<id>/draft_messages' do
    let(:conversation) { create(:conversation, account: account) }
    let(:cache_key) { format(Redis::Alfred::CONVERSATION_DRAFT_MESSAGE, id: conversation.id) }

    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get api_v1_account_conversation_draft_messages_url(account_id: account.id, conversation_id: conversation.display_id)

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user with access to the inbox' do
      let(:agent) { create(:user, account: account, role: :agent) }
      let(:message) { Faker::Lorem.paragraph }

      before do
        create(:inbox_member, inbox: conversation.inbox, user: agent)
      end

      it 'saves the draft message for the conversation' do
        params = { draft_message: { message: message } }

        patch api_v1_account_conversation_draft_messages_url(account_id: account.id, conversation_id: conversation.display_id),
              params: params,
              headers: agent.create_new_auth_token,
              as: :json

        expect(response).to have_http_status(:success)
        expect(Redis::Alfred.get(cache_key)).to eq(params[:draft_message][:message])
      end

      it 'gets the draft message for the conversation' do
        Redis::Alfred.set(cache_key, message)

        get api_v1_account_conversation_draft_messages_url(account_id: account.id, conversation_id: conversation.display_id),
            headers: agent.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        expect(response.body).to include(message)
      end

      it 'removes the draft messages for the conversation' do
        Redis::Alfred.set(cache_key, message)
        expect(Redis::Alfred.get(cache_key)).to eq(message)

        delete api_v1_account_conversation_draft_messages_url(account_id: account.id, conversation_id: conversation.display_id),
               headers: agent.create_new_auth_token,
               as: :json

        expect(response).to have_http_status(:success)
        expect(Redis::Alfred.get(cache_key)).to be_nil
      end
    end
  end
end
