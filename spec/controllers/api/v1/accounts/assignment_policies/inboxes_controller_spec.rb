require 'rails_helper'

RSpec.describe 'Assignment Policy Inboxes API', type: :request do
  let!(:account) { create(:account) }
  let!(:assignment_policy) { create(:assignment_policy, account: account) }
  let!(:inbox1) { create(:inbox, account: account) }
  let!(:inbox2) { create(:inbox, account: account) }
  let!(:inbox3) { create(:inbox, account: account) }

  describe 'GET /api/v1/accounts/{account.id}/assignment_policies/{assignment_policy.id}/inboxes' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get "/api/v1/accounts/#{account.id}/assignment_policies/#{assignment_policy.id}/inboxes"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated admin' do
      let(:admin) { create(:user, account: account, role: :administrator) }

      before do
        create(:inbox_assignment_policy, inbox: inbox1, assignment_policy: assignment_policy)
        create(:inbox_assignment_policy, inbox: inbox2, assignment_policy: assignment_policy)
      end

      it 'returns inboxes associated with the assignment policy' do
        get "/api/v1/accounts/#{account.id}/assignment_policies/#{assignment_policy.id}/inboxes",
            headers: admin.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        json_response = response.parsed_body
        expect(json_response['inboxes']).to be_an(Array)
        expect(json_response['inboxes'].length).to eq(2)
        inbox_ids = json_response['inboxes'].pluck('id')
        expect(inbox_ids).to include(inbox1.id, inbox2.id)
        expect(inbox_ids).not_to include(inbox3.id)
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

  describe 'POST /api/v1/accounts/{account.id}/assignment_policies/{assignment_policy.id}/inboxes' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        post "/api/v1/accounts/#{account.id}/assignment_policies/#{assignment_policy.id}/inboxes"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated admin' do
      let(:admin) { create(:user, account: account, role: :administrator) }

      it 'creates an inbox assignment policy' do
        expect do
          post "/api/v1/accounts/#{account.id}/assignment_policies/#{assignment_policy.id}/inboxes",
               params: { inbox_id: inbox1.id },
               headers: admin.create_new_auth_token,
               as: :json
        end.to change(InboxAssignmentPolicy, :count).by(1)

        expect(response).to have_http_status(:success)
        json_response = response.parsed_body
        expect(json_response['inbox_id']).to eq(inbox1.id)
        expect(json_response['assignment_policy_id']).to eq(assignment_policy.id)
      end

      it 'replaces existing inbox assignment policy' do
        existing_policy = create(:assignment_policy, account: account)
        create(:inbox_assignment_policy, inbox: inbox1, assignment_policy: existing_policy)

        expect do
          post "/api/v1/accounts/#{account.id}/assignment_policies/#{assignment_policy.id}/inboxes",
               params: { inbox_id: inbox1.id },
               headers: admin.create_new_auth_token,
               as: :json
        end.not_to change(InboxAssignmentPolicy, :count)

        expect(response).to have_http_status(:success)
        expect(inbox1.reload.inbox_assignment_policy.assignment_policy).to eq(assignment_policy)
      end

      it 'returns not found for invalid inbox' do
        post "/api/v1/accounts/#{account.id}/assignment_policies/#{assignment_policy.id}/inboxes",
             params: { inbox_id: 999_999 },
             headers: admin.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:not_found)
      end
    end

    context 'when it is an agent' do
      let(:agent) { create(:user, account: account, role: :agent) }

      it 'returns unauthorized' do
        post "/api/v1/accounts/#{account.id}/assignment_policies/#{assignment_policy.id}/inboxes",
             params: { inbox_id: inbox1.id },
             headers: agent.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe 'DELETE /api/v1/accounts/{account.id}/assignment_policies/{assignment_policy.id}/inboxes/{id}' do
    context 'when it is an unauthenticated user' do
      before do
        create(:inbox_assignment_policy, inbox: inbox1, assignment_policy: assignment_policy)
      end

      it 'returns unauthorized' do
        delete "/api/v1/accounts/#{account.id}/assignment_policies/#{assignment_policy.id}/inboxes/#{inbox1.id}"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated admin' do
      let(:admin) { create(:user, account: account, role: :administrator) }

      it 'destroys the inbox assignment policy' do
        create(:inbox_assignment_policy, inbox: inbox1, assignment_policy: assignment_policy)
        expect do
          delete "/api/v1/accounts/#{account.id}/assignment_policies/#{assignment_policy.id}/inboxes/#{inbox1.id}",
                 headers: admin.create_new_auth_token,
                 as: :json
        end.to change(InboxAssignmentPolicy, :count).by(-1)

        expect(response).to have_http_status(:success)
        expect(inbox1.reload.inbox_assignment_policy).to be_nil
      end

      it 'returns success even if inbox assignment policy does not exist' do
        delete "/api/v1/accounts/#{account.id}/assignment_policies/#{assignment_policy.id}/inboxes/#{inbox2.id}",
               headers: admin.create_new_auth_token,
               as: :json

        expect(response).to have_http_status(:success)
      end

      it 'returns not found for invalid inbox' do
        delete "/api/v1/accounts/#{account.id}/assignment_policies/#{assignment_policy.id}/inboxes/999999",
               headers: admin.create_new_auth_token,
               as: :json

        expect(response).to have_http_status(:not_found)
      end
    end

    context 'when it is an agent' do
      let(:agent) { create(:user, account: account, role: :agent) }

      before do
        create(:inbox_assignment_policy, inbox: inbox1, assignment_policy: assignment_policy)
      end

      it 'returns unauthorized' do
        delete "/api/v1/accounts/#{account.id}/assignment_policies/#{assignment_policy.id}/inboxes/#{inbox1.id}",
               headers: agent.create_new_auth_token,
               as: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end
