require 'rails_helper'

RSpec.describe 'Notification Settings API', type: :request do
  let(:account) { create(:account) }

  describe 'GET /api/v1/accounts/{account.id}/notification_settings' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get "/api/v1/accounts/#{account.id}/notification_settings"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      let(:agent) { create(:user, account: account, role: :agent) }

      it 'returns current user notification settings' do
        get "/api/v1/accounts/#{account.id}/notification_settings",
            headers: agent.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        json_response = response.parsed_body
        expect(json_response['user_id']).to eq(agent.id)
        expect(json_response['account_id']).to eq(account.id)
      end
    end
  end

  describe 'PUT /api/v1/accounts/{account.id}/notification_settings' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        put "/api/v1/accounts/#{account.id}/notification_settings"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      let(:agent) { create(:user, account: account, role: :agent) }

      it 'updates the email related notification flags' do
        put "/api/v1/accounts/#{account.id}/notification_settings",
            params: { notification_settings: { selected_email_flags: ['email_conversation_assignment'] } },
            headers: agent.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        json_response = response.parsed_body
        agent.reload
        expect(json_response['user_id']).to eq(agent.id)
        expect(json_response['account_id']).to eq(account.id)
        expect(json_response['selected_email_flags']).to eq(['email_conversation_assignment'])
      end
    end
  end
end
