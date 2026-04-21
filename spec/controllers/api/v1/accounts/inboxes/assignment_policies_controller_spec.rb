require 'rails_helper'

RSpec.describe 'Inbox Assignment Policies API', type: :request do
  let(:account) { create(:account) }
  let(:inbox) { create(:inbox, account: account) }
  let(:assignment_policy) { create(:assignment_policy, account: account) }

  describe 'GET /api/v1/accounts/{account_id}/inboxes/{inbox_id}/assignment_policy' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get "/api/v1/accounts/#{account.id}/inboxes/#{inbox.id}/assignment_policy"
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated admin' do
      let(:admin) { create(:user, account: account, role: :administrator) }

      context 'when inbox has an assignment policy' do
        before do
          create(:inbox_assignment_policy, inbox: inbox, assignment_policy: assignment_policy)
        end

        it 'returns the assignment policy for the inbox' do
          get "/api/v1/accounts/#{account.id}/inboxes/#{inbox.id}/assignment_policy",
              headers: admin.create_new_auth_token,
              as: :json

          expect(response).to have_http_status(:success)
          json_response = response.parsed_body
          expect(json_response['id']).to eq(assignment_policy.id)
          expect(json_response['name']).to eq(assignment_policy.name)
        end
      end

      context 'when inbox has no assignment policy' do
        it 'returns not found' do
          get "/api/v1/accounts/#{account.id}/inboxes/#{inbox.id}/assignment_policy",
              headers: admin.create_new_auth_token,
              as: :json

          expect(response).to have_http_status(:not_found)
        end
      end
    end

    context 'when it is an agent' do
      let(:agent) { create(:user, account: account, role: :agent) }

      it 'returns unauthorized' do
        get "/api/v1/accounts/#{account.id}/inboxes/#{inbox.id}/assignment_policy",
            headers: agent.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe 'POST /api/v1/accounts/{account_id}/inboxes/{inbox_id}/assignment_policy' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        post "/api/v1/accounts/#{account.id}/inboxes/#{inbox.id}/assignment_policy",
             params: { assignment_policy_id: assignment_policy.id }

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated admin' do
      let(:admin) { create(:user, account: account, role: :administrator) }

      it 'assigns a policy to the inbox' do
        expect do
          post "/api/v1/accounts/#{account.id}/inboxes/#{inbox.id}/assignment_policy",
               params: { assignment_policy_id: assignment_policy.id },
               headers: admin.create_new_auth_token,
               as: :json
        end.to change(InboxAssignmentPolicy, :count).by(1)

        expect(response).to have_http_status(:success)
        json_response = response.parsed_body
        expect(json_response['id']).to eq(assignment_policy.id)
      end

      it 'replaces existing assignment policy for inbox' do
        other_policy = create(:assignment_policy, account: account)
        create(:inbox_assignment_policy, inbox: inbox, assignment_policy: other_policy)

        expect do
          post "/api/v1/accounts/#{account.id}/inboxes/#{inbox.id}/assignment_policy",
               params: { assignment_policy_id: assignment_policy.id },
               headers: admin.create_new_auth_token,
               as: :json
        end.not_to change(InboxAssignmentPolicy, :count)

        expect(response).to have_http_status(:success)
        expect(inbox.reload.inbox_assignment_policy.assignment_policy).to eq(assignment_policy)
      end

      it 'returns not found for invalid assignment policy' do
        post "/api/v1/accounts/#{account.id}/inboxes/#{inbox.id}/assignment_policy",
             params: { assignment_policy_id: 999_999 },
             headers: admin.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:not_found)
      end

      it 'returns not found for invalid inbox' do
        post "/api/v1/accounts/#{account.id}/inboxes/999999/assignment_policy",
             params: { assignment_policy_id: assignment_policy.id },
             headers: admin.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:not_found)
      end
    end

    context 'when it is an agent' do
      let(:agent) { create(:user, account: account, role: :agent) }

      it 'returns unauthorized' do
        post "/api/v1/accounts/#{account.id}/inboxes/#{inbox.id}/assignment_policy",
             params: { assignment_policy_id: assignment_policy.id },
             headers: agent.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe 'DELETE /api/v1/accounts/{account_id}/inboxes/{inbox_id}/assignment_policy' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        delete "/api/v1/accounts/#{account.id}/inboxes/#{inbox.id}/assignment_policy"
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated admin' do
      let(:admin) { create(:user, account: account, role: :administrator) }

      context 'when inbox has an assignment policy' do
        before do
          create(:inbox_assignment_policy, inbox: inbox, assignment_policy: assignment_policy)
        end

        it 'removes the assignment policy from inbox' do
          expect do
            delete "/api/v1/accounts/#{account.id}/inboxes/#{inbox.id}/assignment_policy",
                   headers: admin.create_new_auth_token,
                   as: :json
          end.to change(InboxAssignmentPolicy, :count).by(-1)

          expect(response).to have_http_status(:success)
          expect(inbox.reload.inbox_assignment_policy).to be_nil
        end
      end

      context 'when inbox has no assignment policy' do
        it 'returns error' do
          expect do
            delete "/api/v1/accounts/#{account.id}/inboxes/#{inbox.id}/assignment_policy",
                   headers: admin.create_new_auth_token,
                   as: :json
          end.not_to change(InboxAssignmentPolicy, :count)

          expect(response).to have_http_status(:not_found)
        end
      end

      it 'returns not found for invalid inbox' do
        delete "/api/v1/accounts/#{account.id}/inboxes/999999/assignment_policy",
               headers: admin.create_new_auth_token,
               as: :json

        expect(response).to have_http_status(:not_found)
      end
    end

    context 'when it is an agent' do
      let(:agent) { create(:user, account: account, role: :agent) }

      it 'returns unauthorized' do
        delete "/api/v1/accounts/#{account.id}/inboxes/#{inbox.id}/assignment_policy",
               headers: agent.create_new_auth_token,
               as: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end
