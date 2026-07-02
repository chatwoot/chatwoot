require 'rails_helper'

RSpec.describe 'Enterprise Agents API', type: :request do
  let(:account) { create(:account) }
  let(:admin) { create(:user, account: account, role: :administrator) }
  let!(:custom_role) { create(:custom_role, account: account) }

  describe 'POST /api/v1/accounts/{account.id}/agents' do
    let(:params) { { email: 'test@example.com', name: 'Test User', role: 'agent', custom_role_id: custom_role.id } }

    context 'when it is an authenticated administrator' do
      it 'creates an agent with the specified custom role' do
        post "/api/v1/accounts/#{account.id}/agents", headers: admin.create_new_auth_token, params: params, as: :json

        expect(response).to have_http_status(:success)
        agent = account.agents.last
        expect(agent.account_users.first.custom_role_id).to eq(custom_role.id)
        expect(JSON.parse(response.body)['custom_role_id']).to eq(custom_role.id)
      end

      it 'returns Autonomia invitation details without requiring a local agent record' do
        invitation = Autonomia::ProductInvitations::AgentInviter::Result.new(
          email: 'admin@example.com',
          name: 'Admin User',
          role: 'administrator',
          invitation_url: 'https://agents.autonomia.site/accept-invitation?token=test',
          expires_in_hours: 6,
          email_delivery_failed: false,
          manual_share_required: false,
          email_delivery_error: nil
        )
        inviter = instance_double(Autonomia::ProductInvitations::AgentInviter, perform: invitation)

        allow(ENV).to receive(:fetch).and_call_original
        allow(ENV).to receive(:fetch).with('AUTONOMIA_PRODUCT_INVITATIONS_ENABLED', anything).and_return('true')
        allow(Autonomia::ProductInvitations::AgentInviter).to receive(:new).and_return(inviter)

        post "/api/v1/accounts/#{account.id}/agents",
             headers: admin.create_new_auth_token,
             params: { email: 'admin@example.com', name: 'Admin User', role: 'administrator' },
             as: :json

        expect(response).to have_http_status(:created)
        expect(response.parsed_body).to include(
          'pending_invitation' => true,
          'email' => 'admin@example.com',
          'role' => 'administrator',
          'invitation_url' => 'https://agents.autonomia.site/accept-invitation?token=test',
          'expires_in_hours' => 6
        )
      end
    end
  end

  describe 'PUT /api/v1/accounts/{account.id}/agents/:id' do
    let(:other_agent) { create(:user, account: account, role: :agent) }

    context 'when it is an authenticated administrator' do
      it 'modified the custom role of the agent' do
        put "/api/v1/accounts/#{account.id}/agents/#{other_agent.id}",
            headers: admin.create_new_auth_token,
            params: { custom_role_id: custom_role.id },
            as: :json

        expect(response).to have_http_status(:success)
        expect(other_agent.account_users.first.reload.custom_role_id).to eq(custom_role.id)
        expect(JSON.parse(response.body)['custom_role_id']).to eq(custom_role.id)
      end
    end
  end
end
