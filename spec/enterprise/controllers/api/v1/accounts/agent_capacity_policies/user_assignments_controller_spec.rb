require 'rails_helper'

RSpec.describe 'Agent Capacity Policy User Assignments API', type: :request do
  let(:account) { create(:account) }
  let!(:agent_capacity_policy) { create(:agent_capacity_policy, account: account) }
  let!(:user) { create(:user, account: account, role: :agent) }

  describe 'POST /api/v1/accounts/{account.id}/agent_capacity_policies/{policy_id}/user_assignments' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        post "/api/v1/accounts/#{account.id}/agent_capacity_policies/#{agent_capacity_policy.id}/user_assignments",
             params: { user_id: user.id }

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated agent' do
      let(:agent) { create(:user, account: account, role: :agent) }

      it 'returns unauthorized' do
        post "/api/v1/accounts/#{account.id}/agent_capacity_policies/#{agent_capacity_policy.id}/user_assignments",
             params: { user_id: user.id },
             headers: agent.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated administrator' do
      let(:administrator) { create(:user, account: account, role: :administrator) }

      it 'assigns user to the agent capacity policy' do
        post "/api/v1/accounts/#{account.id}/agent_capacity_policies/#{agent_capacity_policy.id}/user_assignments",
             params: { user_id: user.id },
             headers: administrator.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:success)
        json_response = response.parsed_body
        expect(json_response['user']['id']).to eq(user.id)
        expect(json_response['agent_capacity_policy']['id']).to eq(agent_capacity_policy.id)

        # Verify the assignment was persisted
        expect(user.account_users.first.reload.agent_capacity_policy).to eq(agent_capacity_policy)
      end

      it 'returns not found for non-existent user' do
        post "/api/v1/accounts/#{account.id}/agent_capacity_policies/#{agent_capacity_policy.id}/user_assignments",
             params: { user_id: 99_999 },
             headers: administrator.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:not_found)
      end

      it 'returns not found for user from different account' do
        other_user = create(:user, account: create(:account))

        post "/api/v1/accounts/#{account.id}/agent_capacity_policies/#{agent_capacity_policy.id}/user_assignments",
             params: { user_id: other_user.id },
             headers: administrator.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe 'DELETE /api/v1/accounts/{account.id}/agent_capacity_policies/{policy_id}/user_assignments/{user_id}' do
    before do
      user.account_users.first.update!(agent_capacity_policy: agent_capacity_policy)
    end

    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        delete "/api/v1/accounts/#{account.id}/agent_capacity_policies/#{agent_capacity_policy.id}/user_assignments/#{user.id}"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated agent' do
      let(:agent) { create(:user, account: account, role: :agent) }

      it 'returns unauthorized' do
        delete "/api/v1/accounts/#{account.id}/agent_capacity_policies/#{agent_capacity_policy.id}/user_assignments/#{user.id}",
               headers: agent.create_new_auth_token,
               as: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated administrator' do
      let(:administrator) { create(:user, account: account, role: :administrator) }

      it 'removes user from the agent capacity policy' do
        delete "/api/v1/accounts/#{account.id}/agent_capacity_policies/#{agent_capacity_policy.id}/user_assignments/#{user.id}",
               headers: administrator.create_new_auth_token,
               as: :json

        expect(response).to have_http_status(:success)
        expect(response.parsed_body['user']['id']).to eq(user.id)

        # Verify the assignment was removed
        expect(user.account_users.first.reload.agent_capacity_policy).to be_nil
      end

      it 'returns not found for non-existent user' do
        delete "/api/v1/accounts/#{account.id}/agent_capacity_policies/#{agent_capacity_policy.id}/user_assignments/99999",
               headers: administrator.create_new_auth_token,
               as: :json

        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
