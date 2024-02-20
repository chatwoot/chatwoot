require 'rails_helper'

RSpec.describe 'Enterprise Conversations API', type: :request do
  let(:account) { create(:account) }
  let(:admin) { create(:user, account: account, role: :administrator) }

  describe 'PATCH /api/v1/accounts/{account.id}/conversations/:id' do
    let(:conversation) { create(:conversation, account: account) }
    let(:sla_policy) { create(:sla_policy, account: account) }
    let(:params) { { sla_policy_id: sla_policy.id } }

    context 'when it is an authenticated user' do
      let(:agent) { create(:user, account: account, role: :agent) }

      it 'updates the conversation if you are an agent with access to inbox' do
        create(:inbox_member, user: agent, inbox: conversation.inbox)
        patch "/api/v1/accounts/#{account.id}/conversations/#{conversation.display_id}",
              params: params,
              headers: agent.create_new_auth_token,
              as: :json

        expect(response).to have_http_status(:success)
        expect(JSON.parse(response.body, symbolize_names: true)[:sla_policy_id]).to eq(sla_policy.id)
      end
    end
  end
end
