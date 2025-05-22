require 'rails_helper'

RSpec.describe 'Api::V1::Accounts::Captain::CopilotMessagesController', type: :request do
  let(:account) { create(:account) }
  let(:user) { create(:user, account: account, role: :administrator) }
  let(:copilot_thread) { create(:captain_copilot_thread, account: account, user: user) }
  let!(:copilot_message) { create(:captain_copilot_message, copilot_thread: copilot_thread, user: user, account: account) }

  describe 'GET /api/v1/accounts/{account.id}/captain/copilot_threads/{thread.uuid}/copilot_messages' do
    context 'when it is an authenticated user' do
      it 'returns all messages' do
        get "/api/v1/accounts/#{account.id}/captain/copilot_threads/#{copilot_thread.uuid}/copilot_messages",
            headers: user.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        json_response = response.parsed_body
        expect(json_response['payload'].length).to eq(1)
        expect(json_response['payload'][0]['id']).to eq(copilot_message.id)
      end
    end

    context 'when thread uuid is invalid' do
      it 'returns not found error' do
        get "/api/v1/accounts/#{account.id}/captain/copilot_threads/invalid-uuid/copilot_messages",
            headers: user.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
