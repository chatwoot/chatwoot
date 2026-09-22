require 'rails_helper'

RSpec.describe 'Api::V1::Accounts::Captain::CopilotMessagesController', type: :request do
  let(:account) { create(:account) }
  let(:user) { create(:user, account: account, role: :administrator) }
  let(:copilot_thread) { create(:captain_copilot_thread, account: account, user: user) }
  let!(:copilot_message) { create(:captain_copilot_message, copilot_thread: copilot_thread, account: account) }

  describe 'GET /api/v1/accounts/{account.id}/captain/copilot_threads/{thread.id}/copilot_messages' do
    context 'when it is an authenticated user' do
      it 'returns all messages' do
        get "/api/v1/accounts/#{account.id}/captain/copilot_threads/#{copilot_thread.id}/copilot_messages",
            headers: user.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        json_response = response.parsed_body
        expect(json_response['payload'].length).to eq(1)
        expect(json_response['payload'][0]['id']).to eq(copilot_message.id)
      end

      it 'pages recent history in display order, including messages with the same timestamp' do
        messages = create_list(:captain_copilot_message, 24, account: account, copilot_thread: copilot_thread)
        all_messages = [copilot_message, *messages]
        timestamp = Time.current.change(usec: 0)
        all_messages.each { |message| message.update!(created_at: timestamp) }
        headers = user.create_new_auth_token
        path = "/api/v1/accounts/#{account.id}/captain/copilot_threads/#{copilot_thread.id}/copilot_messages"

        get path, params: { history: true }, headers: headers, as: :json

        expect(response).to have_http_status(:success)
        expect(response.parsed_body['payload'].pluck('id')).to eq(all_messages.last(20).pluck(:id))
        expect(response.parsed_body['meta']).to eq('page' => 1, 'total_count' => 25, 'next_page' => 2)

        get path, params: { history: true, page: 2 }, headers: headers, as: :json

        expect(response.parsed_body['payload'].pluck('id')).to eq(all_messages.first(5).pluck(:id))
        expect(response.parsed_body['meta']).to eq('page' => 2, 'total_count' => 25, 'next_page' => nil)

        get path, headers: headers, as: :json

        expect(response.parsed_body['payload'].pluck('id')).to eq(all_messages.pluck(:id))
      end

      it 'does not expose another owner history' do
        other_user = create(:user, account: account)
        get "/api/v1/accounts/#{account.id}/captain/copilot_threads/#{copilot_thread.id}/copilot_messages",
            params: { history: true }, headers: other_user.create_new_auth_token, as: :json

        expect(response).to have_http_status(:not_found)
      end
    end

    context 'when thread id is invalid' do
      it 'returns not found error' do
        get "/api/v1/accounts/#{account.id}/captain/copilot_threads/999999999/copilot_messages",
            headers: user.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe 'POST /api/v1/accounts/{account.id}/captain/copilot_threads/{thread.id}/copilot_messages' do
    context 'when it is an authenticated user' do
      it 'creates a new message' do
        message_content = { 'content' => 'This is a test message' }

        expect do
          post "/api/v1/accounts/#{account.id}/captain/copilot_threads/#{copilot_thread.id}/copilot_messages",
               params: { message: message_content },
               headers: user.create_new_auth_token,
               as: :json
        end.to change(CopilotMessage, :count).by(1)

        expect(response).to have_http_status(:success)
        expect(CopilotMessage.last.message).to eq({ 'content' => message_content })
        expect(CopilotMessage.last.message_type).to eq('user')
        expect(CopilotMessage.last.copilot_thread_id).to eq(copilot_thread.id)
      end
    end

    context 'when thread does not exist' do
      it 'returns not found error' do
        post "/api/v1/accounts/#{account.id}/captain/copilot_threads/999999999/copilot_messages",
             params: { message: { text: 'Test message' } },
             headers: user.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:not_found)
      end
    end

    context 'when thread belongs to another user' do
      let(:another_user) { create(:user, account: account) }
      let(:another_thread) { create(:captain_copilot_thread, account: account, user: another_user) }

      it 'returns not found error' do
        post "/api/v1/accounts/#{account.id}/captain/copilot_threads/#{another_thread.id}/copilot_messages",
             params: { message: { text: 'Test message' } },
             headers: user.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
