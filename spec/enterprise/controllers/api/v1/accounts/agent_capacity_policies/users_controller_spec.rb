require 'rails_helper'

RSpec.describe 'Agent Capacity Policies Users API', type: :request do
  let(:account) { create(:account) }
  let!(:agent_capacity_policy) { create(:agent_capacity_policy, account: account) }
  let!(:user) { create(:user, account: account, role: :agent) }

  describe 'POST /api/v1/accounts/{account.id}/agent_capacity_policies/{policy_id}/users/{user_id}/assign' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        post "/api/v1/accounts/#{account.id}/agent_capacity_policies/#{agent_capacity_policy.id}/users/#{user.id}/assign"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      let(:agent) { create(:user, account: account, role: :agent) }
      let(:administrator) { create(:user, account: account, role: :administrator) }

      it 'returns unauthorized for agent' do
        post "/api/v1/accounts/#{account.id}/agent_capacity_policies/#{agent_capacity_policy.id}/users/#{user.id}/assign",
             headers: agent.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:unauthorized)
      end

      it 'assigns user to agent capacity policy when administrator' do
        post "/api/v1/accounts/#{account.id}/agent_capacity_policies/#{agent_capacity_policy.id}/users/#{user.id}/assign",
             headers: administrator.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:success)
        expect(response.parsed_body['user']['id']).to eq(user.id)
        expect(response.parsed_body['agent_capacity_policy']['id']).to eq(agent_capacity_policy.id)

        user.account_users.first.reload
        expect(user.account_users.first.agent_capacity_policy).to eq(agent_capacity_policy)
      end

      it 'returns not found for invalid user' do
        post "/api/v1/accounts/#{account.id}/agent_capacity_policies/#{agent_capacity_policy.id}/users/99999/assign",
             headers: administrator.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:not_found)
      end

      it 'returns not found for invalid policy' do
        post "/api/v1/accounts/#{account.id}/agent_capacity_policies/99999/users/#{user.id}/assign",
             headers: administrator.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:not_found)
      end

      it 'returns not found for user from different account' do
        other_account = create(:account)
        other_user = create(:user, account: other_account, role: :agent)

        post "/api/v1/accounts/#{account.id}/agent_capacity_policies/#{agent_capacity_policy.id}/users/#{other_user.id}/assign",
             headers: administrator.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe 'DELETE /api/v1/accounts/{account.id}/agent_capacity_policies/{policy_id}/users/{user_id}/unassign' do
    before do
      user.account_users.first.update!(agent_capacity_policy: agent_capacity_policy)
    end

    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        delete "/api/v1/accounts/#{account.id}/agent_capacity_policies/#{agent_capacity_policy.id}/users/#{user.id}/unassign"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      let(:agent) { create(:user, account: account, role: :agent) }
      let(:administrator) { create(:user, account: account, role: :administrator) }

      it 'returns unauthorized for agent' do
        delete "/api/v1/accounts/#{account.id}/agent_capacity_policies/#{agent_capacity_policy.id}/users/#{user.id}/unassign",
               headers: agent.create_new_auth_token,
               as: :json

        expect(response).to have_http_status(:unauthorized)
      end

      it 'unassigns user from agent capacity policy when administrator' do
        delete "/api/v1/accounts/#{account.id}/agent_capacity_policies/#{agent_capacity_policy.id}/users/#{user.id}/unassign",
               headers: administrator.create_new_auth_token,
               as: :json

        expect(response).to have_http_status(:success)
        expect(response.parsed_body['user']['id']).to eq(user.id)

        user.account_users.first.reload
        expect(user.account_users.first.agent_capacity_policy).to be_nil
      end

      it 'returns not found for invalid user' do
        delete "/api/v1/accounts/#{account.id}/agent_capacity_policies/#{agent_capacity_policy.id}/users/99999/unassign",
               headers: administrator.create_new_auth_token,
               as: :json

        expect(response).to have_http_status(:not_found)
      end

      it 'returns not found for invalid policy' do
        delete "/api/v1/accounts/#{account.id}/agent_capacity_policies/99999/users/#{user.id}/unassign",
               headers: administrator.create_new_auth_token,
               as: :json

        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
