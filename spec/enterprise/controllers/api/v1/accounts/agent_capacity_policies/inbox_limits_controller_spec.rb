require 'rails_helper'

RSpec.describe 'Agent Capacity Policy Inbox Limits API', type: :request do
  let(:account) { create(:account) }
  let!(:agent_capacity_policy) { create(:agent_capacity_policy, account: account) }
  let!(:inbox) { create(:inbox, account: account) }

  describe 'POST /api/v1/accounts/{account.id}/agent_capacity_policies/{policy_id}/inbox_limits' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        post "/api/v1/accounts/#{account.id}/agent_capacity_policies/#{agent_capacity_policy.id}/inbox_limits",
             params: { inbox_id: inbox.id, conversation_limit: 10 }

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated agent' do
      let(:agent) { create(:user, account: account, role: :agent) }

      it 'returns unauthorized' do
        post "/api/v1/accounts/#{account.id}/agent_capacity_policies/#{agent_capacity_policy.id}/inbox_limits",
             params: { inbox_id: inbox.id, conversation_limit: 10 },
             headers: agent.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated administrator' do
      let(:administrator) { create(:user, account: account, role: :administrator) }

      it 'creates an inbox limit' do
        post "/api/v1/accounts/#{account.id}/agent_capacity_policies/#{agent_capacity_policy.id}/inbox_limits",
             params: { inbox_id: inbox.id, conversation_limit: 10 },
             headers: administrator.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:success)
        json_response = response.parsed_body
        expect(json_response['conversation_limit']).to eq(10)
        expect(json_response['inbox_id']).to eq(inbox.id)
        expect(json_response['agent_capacity_policy_id']).to eq(agent_capacity_policy.id)
      end

      it 'returns validation error for invalid conversation limit' do
        post "/api/v1/accounts/#{account.id}/agent_capacity_policies/#{agent_capacity_policy.id}/inbox_limits",
             params: { inbox_id: inbox.id, conversation_limit: -1 },
             headers: administrator.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'returns not found for non-existent inbox' do
        post "/api/v1/accounts/#{account.id}/agent_capacity_policies/#{agent_capacity_policy.id}/inbox_limits",
             params: { inbox_id: 99_999, conversation_limit: 10 },
             headers: administrator.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe 'PUT /api/v1/accounts/{account.id}/agent_capacity_policies/{policy_id}/inbox_limits/{inbox_id}' do
    let!(:inbox_limit) { create(:inbox_capacity_limit, agent_capacity_policy: agent_capacity_policy, inbox: inbox, conversation_limit: 5) }

    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        put "/api/v1/accounts/#{account.id}/agent_capacity_policies/#{agent_capacity_policy.id}/inbox_limits/#{inbox.id}"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated agent' do
      let(:agent) { create(:user, account: account, role: :agent) }

      it 'returns unauthorized' do
        put "/api/v1/accounts/#{account.id}/agent_capacity_policies/#{agent_capacity_policy.id}/inbox_limits/#{inbox.id}",
            params: { conversation_limit: 15 },
            headers: agent.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated administrator' do
      let(:administrator) { create(:user, account: account, role: :administrator) }

      it 'updates the inbox limit' do
        put "/api/v1/accounts/#{account.id}/agent_capacity_policies/#{agent_capacity_policy.id}/inbox_limits/#{inbox.id}",
            params: { conversation_limit: 15 },
            headers: administrator.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        json_response = response.parsed_body
        expect(json_response['conversation_limit']).to eq(15)
        expect(json_response['inbox_id']).to eq(inbox.id)

        # Verify the update was persisted
        expect(inbox_limit.reload.conversation_limit).to eq(15)
      end

      it 'returns validation error for invalid conversation limit' do
        put "/api/v1/accounts/#{account.id}/agent_capacity_policies/#{agent_capacity_policy.id}/inbox_limits/#{inbox.id}",
            params: { conversation_limit: -1 },
            headers: administrator.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'returns not found when inbox limit does not exist' do
        other_inbox = create(:inbox, account: account)

        put "/api/v1/accounts/#{account.id}/agent_capacity_policies/#{agent_capacity_policy.id}/inbox_limits/#{other_inbox.id}",
            params: { conversation_limit: 10 },
            headers: administrator.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe 'DELETE /api/v1/accounts/{account.id}/agent_capacity_policies/{policy_id}/inbox_limits/{inbox_id}' do
    before do
      create(:inbox_capacity_limit, agent_capacity_policy: agent_capacity_policy, inbox: inbox)
    end

    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        delete "/api/v1/accounts/#{account.id}/agent_capacity_policies/#{agent_capacity_policy.id}/inbox_limits/#{inbox.id}"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated agent' do
      let(:agent) { create(:user, account: account, role: :agent) }

      it 'returns unauthorized' do
        delete "/api/v1/accounts/#{account.id}/agent_capacity_policies/#{agent_capacity_policy.id}/inbox_limits/#{inbox.id}",
               headers: agent.create_new_auth_token,
               as: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated administrator' do
      let(:administrator) { create(:user, account: account, role: :administrator) }

      it 'removes the inbox limit' do
        delete "/api/v1/accounts/#{account.id}/agent_capacity_policies/#{agent_capacity_policy.id}/inbox_limits/#{inbox.id}",
               headers: administrator.create_new_auth_token,
               as: :json

        expect(response).to have_http_status(:no_content)

        # Verify the inbox limit was deleted
        expect(agent_capacity_policy.inbox_capacity_limits.find_by(inbox: inbox)).to be_nil
      end

      it 'returns not found when inbox limit does not exist' do
        other_inbox = create(:inbox, account: account)

        delete "/api/v1/accounts/#{account.id}/agent_capacity_policies/#{agent_capacity_policy.id}/inbox_limits/#{other_inbox.id}",
               headers: administrator.create_new_auth_token,
               as: :json

        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
