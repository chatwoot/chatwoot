require 'rails_helper'

RSpec.describe 'Conversations API', type: :request do
  let(:account) { create(:account) }

  describe 'GET /api/v1/conversations' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get '/api/v1/conversations'

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      let(:agent) { create(:user, account: account, role: :agent) }

      before do
        conversation = create(:conversation, account: account)
        create(:inbox_member, user: agent, inbox: conversation.inbox)
      end

      it 'returns all conversations' do
        get '/api/v1/conversations',
            headers: agent.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        expect(JSON.parse(response.body, symbolize_names: true)[:data][:meta][:all_count]).to eq(1)
      end
    end
  end

  describe 'GET /api/v1/conversations/:id' do
    let(:conversation) { create(:conversation, account: account) }

    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get "/api/v1/conversations/#{conversation.display_id}"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      let(:agent) { create(:user, account: account, role: :agent) }

      it 'shows the conversation' do
        get "/api/v1/conversations/#{conversation.display_id}",
            headers: agent.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        expect(JSON.parse(response.body, symbolize_names: true)[:meta][:contact_id]).to eq(conversation.contact_id)
      end
    end
  end

  describe 'POST /api/v1/conversations/:id/toggle_status' do
    let(:conversation) { create(:conversation, account: account) }

    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        post "/api/v1/conversations/#{conversation.display_id}/toggle_status"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      let(:agent) { create(:user, account: account, role: :agent) }

      it 'toggles the conversation status' do
        expect(conversation.status).to eq('open')

        post "/api/v1/conversations/#{conversation.display_id}/toggle_status",
             headers: agent.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:success)
        expect(conversation.reload.status).to eq('resolved')
      end
    end
  end

  describe 'POST /api/v1/conversations/:id/update_last_seen' do
    let(:conversation) { create(:conversation, account: account) }

    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        post "/api/v1/conversations/#{conversation.display_id}/update_last_seen"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      let(:agent) { create(:user, account: account, role: :agent) }

      it 'updates last seen' do
        params = { agent_last_seen_at: '-1' }

        post "/api/v1/conversations/#{conversation.display_id}/update_last_seen",
             headers: agent.create_new_auth_token,
             params: params,
             as: :json

        expect(response).to have_http_status(:success)
        expect(conversation.reload.agent_last_seen_at).to eq(DateTime.strptime(params[:agent_last_seen_at].to_s, '%s'))
      end
    end
  end

  describe 'GET /api/v1/conversations/:id/get_messages' do
    let(:conversation) { create(:conversation, account: account) }
    let!(:message) { create(:message, conversation: conversation, account: account, inbox: conversation.inbox) }

    context 'when it is an unauthenticated user' do
      it 'returns the messages' do
        get "/api/v1/conversations/#{conversation.id}/get_messages"

        expect(response).to have_http_status(:success)
        expect(JSON.parse(response.body, symbolize_names: true)[:payload].size).to eq(4)
        expect(response.body).to include(message.content)
      end
    end

    context 'when it is an authenticated user' do
      let(:agent) { create(:user, account: account, role: :agent) }

      it 'returns the messages' do
        get "/api/v1/conversations/#{conversation.id}/get_messages",
            headers: agent.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        expect(JSON.parse(response.body, symbolize_names: true)[:payload].size).to eq(4)
        expect(response.body).to include(message.content)
      end
    end
  end
end
