require 'rails_helper'

RSpec.describe 'Assignment Policy Inboxes API', type: :request do
  let(:account) { create(:account) }
  let(:assignment_policy) { create(:assignment_policy, account: account) }

  describe 'GET /api/v1/accounts/{account_id}/assignment_policies/{assignment_policy_id}/inboxes' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get "/api/v1/accounts/#{account.id}/assignment_policies/#{assignment_policy.id}/inboxes"
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated admin' do
      let(:admin) { create(:user, account: account, role: :administrator) }

      context 'when assignment policy has associated inboxes' do
        before do
          inbox1 = create(:inbox, account: account)
          inbox2 = create(:inbox, account: account)
          create(:inbox_assignment_policy, inbox: inbox1, assignment_policy: assignment_policy)
          create(:inbox_assignment_policy, inbox: inbox2, assignment_policy: assignment_policy)
        end

        it 'returns all inboxes associated with the assignment policy' do
          get "/api/v1/accounts/#{account.id}/assignment_policies/#{assignment_policy.id}/inboxes",
              headers: admin.create_new_auth_token,
              as: :json

          expect(response).to have_http_status(:success)
          json_response = response.parsed_body
          expect(json_response['inboxes']).to be_an(Array)
          expect(json_response['inboxes'].length).to eq(2)
        end
      end

      context 'when assignment policy has no associated inboxes' do
        it 'returns empty array' do
          get "/api/v1/accounts/#{account.id}/assignment_policies/#{assignment_policy.id}/inboxes",
              headers: admin.create_new_auth_token,
              as: :json

          expect(response).to have_http_status(:success)
          json_response = response.parsed_body
          expect(json_response['inboxes']).to eq([])
        end
      end
    end

    context 'when it is an agent' do
      let(:agent) { create(:user, account: account, role: :agent) }

      it 'returns unauthorized' do
        get "/api/v1/accounts/#{account.id}/assignment_policies/#{assignment_policy.id}/inboxes",
            headers: agent.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end
