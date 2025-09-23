require 'rails_helper'

RSpec.describe 'Agent Capacity Policies API', type: :request do
  let(:account) { create(:account) }
  let!(:agent_capacity_policy) { create(:agent_capacity_policy, account: account) }

  describe 'GET /api/v1/accounts/{account.id}/agent_capacity_policies' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get "/api/v1/accounts/#{account.id}/agent_capacity_policies"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated agent' do
      let(:agent) { create(:user, account: account, role: :agent) }

      it 'returns unauthorized for agent' do
        get "/api/v1/accounts/#{account.id}/agent_capacity_policies",
            headers: agent.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an administrator' do
      let(:administrator) { create(:user, account: account, role: :administrator) }

      it 'returns all agent capacity policies' do
        get "/api/v1/accounts/#{account.id}/agent_capacity_policies",
            headers: administrator.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        expect(response.parsed_body.first['id']).to eq(agent_capacity_policy.id)
      end
    end
  end

  describe 'GET /api/v1/accounts/{account.id}/agent_capacity_policies/{id}' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get "/api/v1/accounts/#{account.id}/agent_capacity_policies/#{agent_capacity_policy.id}"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated agent' do
      let(:agent) { create(:user, account: account, role: :agent) }

      it 'returns unauthorized for agent' do
        get "/api/v1/accounts/#{account.id}/agent_capacity_policies/#{agent_capacity_policy.id}",
            headers: agent.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an administrator' do
      let(:administrator) { create(:user, account: account, role: :administrator) }

      it 'returns the agent capacity policy' do
        get "/api/v1/accounts/#{account.id}/agent_capacity_policies/#{agent_capacity_policy.id}",
            headers: administrator.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        expect(response.parsed_body['id']).to eq(agent_capacity_policy.id)
      end
    end
  end

  describe 'POST /api/v1/accounts/{account.id}/agent_capacity_policies' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        post "/api/v1/accounts/#{account.id}/agent_capacity_policies"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      let(:agent) { create(:user, account: account, role: :agent) }
      let(:administrator) { create(:user, account: account, role: :administrator) }

      it 'returns unauthorized for agent' do
        params = { agent_capacity_policy: { name: 'Test Policy' } }

        post "/api/v1/accounts/#{account.id}/agent_capacity_policies",
             params: params,
             headers: agent.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:unauthorized)
      end

      it 'creates a new agent capacity policy when administrator' do
        params = {
          agent_capacity_policy: {
            name: 'Test Policy',
            description: 'Test Description',
            exclusion_rules: {
              excluded_labels: %w[urgent spam],
              exclude_older_than_hours: 24
            }
          }
        }

        post "/api/v1/accounts/#{account.id}/agent_capacity_policies",
             params: params,
             headers: administrator.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:success)
        expect(response.parsed_body['name']).to eq('Test Policy')
        expect(response.parsed_body['description']).to eq('Test Description')
        expect(response.parsed_body['exclusion_rules']).to eq({
                                                                'excluded_labels' => %w[urgent spam],
                                                                'exclude_older_than_hours' => 24
                                                              })
      end

      it 'returns validation errors for invalid data' do
        params = { agent_capacity_policy: { name: '' } }

        post "/api/v1/accounts/#{account.id}/agent_capacity_policies",
             params: params,
             headers: administrator.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe 'PUT /api/v1/accounts/{account.id}/agent_capacity_policies/{id}' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        put "/api/v1/accounts/#{account.id}/agent_capacity_policies/#{agent_capacity_policy.id}"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      let(:agent) { create(:user, account: account, role: :agent) }
      let(:administrator) { create(:user, account: account, role: :administrator) }

      it 'returns unauthorized for agent' do
        params = { agent_capacity_policy: { name: 'Updated Policy' } }

        put "/api/v1/accounts/#{account.id}/agent_capacity_policies/#{agent_capacity_policy.id}",
            params: params,
            headers: agent.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:unauthorized)
      end

      it 'updates the agent capacity policy when administrator' do
        params = { agent_capacity_policy: { name: 'Updated Policy' } }

        put "/api/v1/accounts/#{account.id}/agent_capacity_policies/#{agent_capacity_policy.id}",
            params: params,
            headers: administrator.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        expect(response.parsed_body['name']).to eq('Updated Policy')
      end

      it 'updates exclusion rules when administrator' do
        params = {
          agent_capacity_policy: {
            exclusion_rules: {
              excluded_labels: %w[vip priority],
              exclude_older_than_hours: 48
            }
          }
        }

        put "/api/v1/accounts/#{account.id}/agent_capacity_policies/#{agent_capacity_policy.id}",
            params: params,
            headers: administrator.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        expect(response.parsed_body['exclusion_rules']).to eq({
                                                                'excluded_labels' => %w[vip priority],
                                                                'exclude_older_than_hours' => 48
                                                              })
      end
    end
  end

  describe 'DELETE /api/v1/accounts/{account.id}/agent_capacity_policies/{id}' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        delete "/api/v1/accounts/#{account.id}/agent_capacity_policies/#{agent_capacity_policy.id}"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      let(:agent) { create(:user, account: account, role: :agent) }
      let(:administrator) { create(:user, account: account, role: :administrator) }

      it 'returns unauthorized for agent' do
        delete "/api/v1/accounts/#{account.id}/agent_capacity_policies/#{agent_capacity_policy.id}",
               headers: agent.create_new_auth_token,
               as: :json

        expect(response).to have_http_status(:unauthorized)
      end

      it 'deletes the agent capacity policy when administrator' do
        delete "/api/v1/accounts/#{account.id}/agent_capacity_policies/#{agent_capacity_policy.id}",
               headers: administrator.create_new_auth_token,
               as: :json

        expect(response).to have_http_status(:ok)
        expect { agent_capacity_policy.reload }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end
end
