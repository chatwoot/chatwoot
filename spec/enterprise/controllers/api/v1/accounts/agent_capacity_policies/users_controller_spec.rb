require 'rails_helper'

RSpec.describe 'Agent Capacity Policy Users API', type: :request do
  let(:account) { create(:account) }
  let!(:agent_capacity_policy) { create(:agent_capacity_policy, account: account) }
  let!(:user) { create(:user, account: account, role: :agent) }
  let(:administrator) { create(:user, account: account, role: :administrator) }
  let(:agent) { create(:user, account: account, role: :agent) }

  describe 'GET /api/v1/accounts/{account.id}/agent_capacity_policies/{policy_id}/users' do
    context 'when admin' do
      it 'returns assigned users' do
        user.account_users.first.update!(agent_capacity_policy: agent_capacity_policy)

        get "/api/v1/accounts/#{account.id}/agent_capacity_policies/#{agent_capacity_policy.id}/users",
            headers: administrator.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        expect(response.parsed_body.first['id']).to eq(user.id)
      end

      it 'returns each user only once without duplicates' do
        # Assign multiple users to the same policy
        user.account_users.first.update!(agent_capacity_policy: agent_capacity_policy)
        agent.account_users.first.update!(agent_capacity_policy: agent_capacity_policy)

        get "/api/v1/accounts/#{account.id}/agent_capacity_policies/#{agent_capacity_policy.id}/users",
            headers: administrator.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)

        # Check that we have exactly 2 users
        expect(response.parsed_body.length).to eq(2)

        # Check that each user appears only once
        user_ids = response.parsed_body.map { |u| u['id'] }
        expect(user_ids).to contain_exactly(user.id, agent.id)
        expect(user_ids.uniq).to eq(user_ids) # No duplicates
      end
    end
  end

  describe 'POST /api/v1/accounts/{account.id}/agent_capacity_policies/{policy_id}/users' do
    context 'when not admin' do
      it 'requires admin role' do
        post "/api/v1/accounts/#{account.id}/agent_capacity_policies/#{agent_capacity_policy.id}/users",
             params: { user_id: user.id },
             headers: agent.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when admin' do
      it 'assigns user to the policy' do
        post "/api/v1/accounts/#{account.id}/agent_capacity_policies/#{agent_capacity_policy.id}/users",
             params: { user_id: user.id },
             headers: administrator.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:success)
        expect(user.account_users.first.reload.agent_capacity_policy).to eq(agent_capacity_policy)
      end
    end
  end

  describe 'DELETE /api/v1/accounts/{account.id}/agent_capacity_policies/{policy_id}/users/{id}' do
    context 'when admin' do
      before do
        user.account_users.first.update!(agent_capacity_policy: agent_capacity_policy)
      end

      it 'removes user from the policy' do
        delete "/api/v1/accounts/#{account.id}/agent_capacity_policies/#{agent_capacity_policy.id}/users/#{user.id}",
               headers: administrator.create_new_auth_token,
               as: :json

        expect(response).to have_http_status(:ok)
        expect(user.account_users.first.reload.agent_capacity_policy).to be_nil
      end
    end
  end
end
