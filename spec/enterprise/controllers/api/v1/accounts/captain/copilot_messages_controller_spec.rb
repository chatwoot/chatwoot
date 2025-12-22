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
