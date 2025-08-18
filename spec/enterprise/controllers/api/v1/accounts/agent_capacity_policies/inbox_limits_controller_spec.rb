require 'rails_helper'

RSpec.describe 'Agent Capacity Policies Inbox Limits API', type: :request do
  let(:account) { create(:account) }
  let!(:agent_capacity_policy) { create(:agent_capacity_policy, account: account) }
  let!(:inbox) { create(:inbox, account: account) }

  describe 'PUT /api/v1/accounts/{account.id}/agent_capacity_policies/{policy_id}/inbox_limits/{inbox_id}' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        put "/api/v1/accounts/#{account.id}/agent_capacity_policies/#{agent_capacity_policy.id}/inbox_limits/#{inbox.id}"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      let(:agent) { create(:user, account: account, role: :agent) }
      let(:administrator) { create(:user, account: account, role: :administrator) }

      it 'returns unauthorized for agent' do
        params = { conversation_limit: 10 }

        put "/api/v1/accounts/#{account.id}/agent_capacity_policies/#{agent_capacity_policy.id}/inbox_limits/#{inbox.id}",
            params: params,
            headers: agent.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:unauthorized)
      end

      it 'updates the inbox limit when administrator' do
        create(:inbox_capacity_limit, agent_capacity_policy: agent_capacity_policy, inbox: inbox)
        params = { conversation_limit: 15 }

        put "/api/v1/accounts/#{account.id}/agent_capacity_policies/#{agent_capacity_policy.id}/inbox_limits/#{inbox.id}",
            params: params,
            headers: administrator.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        expect(response.parsed_body['conversation_limit']).to eq(15)
        expect(response.parsed_body['inbox_id']).to eq(inbox.id)
        expect(response.parsed_body['inbox_name']).to eq(inbox.name)
      end

      it 'creates a new inbox limit if it does not exist' do
        new_inbox = create(:inbox, account: account)
        params = { conversation_limit: 8 }

        put "/api/v1/accounts/#{account.id}/agent_capacity_policies/#{agent_capacity_policy.id}/inbox_limits/#{new_inbox.id}",
            params: params,
            headers: administrator.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        expect(response.parsed_body['conversation_limit']).to eq(8)
        expect(response.parsed_body['inbox_id']).to eq(new_inbox.id)
      end

      it 'returns validation errors for invalid data' do
        params = { conversation_limit: -1 }

        put "/api/v1/accounts/#{account.id}/agent_capacity_policies/#{agent_capacity_policy.id}/inbox_limits/#{inbox.id}",
            params: params,
            headers: administrator.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'returns not found for invalid inbox' do
        params = { conversation_limit: 10 }

        put "/api/v1/accounts/#{account.id}/agent_capacity_policies/#{agent_capacity_policy.id}/inbox_limits/99999",
            params: params,
            headers: administrator.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:not_found)
      end

      it 'returns not found for invalid policy' do
        params = { conversation_limit: 10 }

        put "/api/v1/accounts/#{account.id}/agent_capacity_policies/99999/inbox_limits/#{inbox.id}",
            params: params,
            headers: administrator.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
