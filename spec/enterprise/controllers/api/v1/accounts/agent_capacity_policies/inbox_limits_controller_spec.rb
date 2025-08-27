require 'rails_helper'

RSpec.describe 'Agent Capacity Policy Inbox Limits API', type: :request do
  let(:account) { create(:account) }
  let!(:agent_capacity_policy) { create(:agent_capacity_policy, account: account) }
  let!(:inbox) { create(:inbox, account: account) }
  let(:administrator) { create(:user, account: account, role: :administrator) }
  let(:agent) { create(:user, account: account, role: :agent) }

  describe 'POST /api/v1/accounts/{account.id}/agent_capacity_policies/{policy_id}/inbox_limits' do
    context 'when not admin' do
      it 'requires admin role' do
        post "/api/v1/accounts/#{account.id}/agent_capacity_policies/#{agent_capacity_policy.id}/inbox_limits",
             params: { inbox_id: inbox.id, conversation_limit: 10 },
             headers: agent.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when admin' do
      it 'creates an inbox limit' do
        post "/api/v1/accounts/#{account.id}/agent_capacity_policies/#{agent_capacity_policy.id}/inbox_limits",
             params: { inbox_id: inbox.id, conversation_limit: 10 },
             headers: administrator.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:success)
        json_response = response.parsed_body
        expect(json_response['conversation_limit']).to eq(10)
        expect(json_response['inbox_id']).to eq(inbox.id)
      end

      it 'prevents duplicate inbox assignments' do
        create(:inbox_capacity_limit, agent_capacity_policy: agent_capacity_policy, inbox: inbox)

        post "/api/v1/accounts/#{account.id}/agent_capacity_policies/#{agent_capacity_policy.id}/inbox_limits",
             params: { inbox_id: inbox.id, conversation_limit: 10 },
             headers: administrator.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.parsed_body['error']).to eq(I18n.t('agent_capacity_policy.inbox_already_assigned'))
      end
    end
  end

  describe 'PUT /api/v1/accounts/{account.id}/agent_capacity_policies/{policy_id}/inbox_limits/{id}' do
    let!(:inbox_limit) { create(:inbox_capacity_limit, agent_capacity_policy: agent_capacity_policy, inbox: inbox, conversation_limit: 5) }

    context 'when admin' do
      it 'updates the inbox limit' do
        put "/api/v1/accounts/#{account.id}/agent_capacity_policies/#{agent_capacity_policy.id}/inbox_limits/#{inbox_limit.id}",
            params: { conversation_limit: 15 },
            headers: administrator.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        expect(response.parsed_body['conversation_limit']).to eq(15)
        expect(inbox_limit.reload.conversation_limit).to eq(15)
      end
    end
  end

  describe 'DELETE /api/v1/accounts/{account.id}/agent_capacity_policies/{policy_id}/inbox_limits/{id}' do
    let!(:inbox_limit) { create(:inbox_capacity_limit, agent_capacity_policy: agent_capacity_policy, inbox: inbox) }

    context 'when admin' do
      it 'removes the inbox limit' do
        delete "/api/v1/accounts/#{account.id}/agent_capacity_policies/#{agent_capacity_policy.id}/inbox_limits/#{inbox_limit.id}",
               headers: administrator.create_new_auth_token,
               as: :json

        expect(response).to have_http_status(:no_content)
        expect(agent_capacity_policy.inbox_capacity_limits.find_by(id: inbox_limit.id)).to be_nil
      end
    end
  end
end
