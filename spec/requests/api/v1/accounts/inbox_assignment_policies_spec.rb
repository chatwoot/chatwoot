# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Api::V1::Accounts::InboxAssignmentPolicies', type: :request do
  let(:account) { create(:account) }
  let(:admin) { create(:user, account: account, role: :administrator) }
  let(:agent) { create(:user, account: account, role: :agent) }
  let(:assignment_policy) { create(:assignment_policy, account: account) }
  let(:inbox) { create(:inbox, account: account) }

  describe 'GET /api/v1/accounts/{account.id}/assignment_policies/{assignment_policy_id}/inboxes' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get "/api/v1/accounts/#{account.id}/assignment_policies/#{assignment_policy.id}/inboxes"
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated admin' do
      before do
        create(:inbox_assignment_policy, inbox: inbox, assignment_policy: assignment_policy)
      end

      it 'returns the list of inboxes for the assignment policy' do
        get "/api/v1/accounts/#{account.id}/assignment_policies/#{assignment_policy.id}/inboxes",
            headers: admin.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        json_response = response.parsed_body
        expect(json_response['inboxes']).to be_an(Array)
        expect(json_response['inboxes'].first['id']).to eq(inbox.id)
      end

      it 'returns empty array when no inboxes are assigned' do
        unassigned_policy = create(:assignment_policy, account: account, name: 'Unassigned Policy')

        get "/api/v1/accounts/#{account.id}/assignment_policies/#{unassigned_policy.id}/inboxes",
            headers: admin.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        json_response = response.parsed_body
        expect(json_response['inboxes']).to eq([])
      end
    end

    context 'when it is an agent' do
      it 'returns unauthorized' do
        get "/api/v1/accounts/#{account.id}/assignment_policies/#{assignment_policy.id}/inboxes",
            headers: agent.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe 'GET /api/v1/accounts/{account.id}/inboxes/{inbox_id}/assignment_policy' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get "/api/v1/accounts/#{account.id}/inboxes/#{inbox.id}/assignment_policy"
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated admin' do
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
          expect(json_response['inbox_assignment_policy']).to be_present
          expect(json_response['inbox_assignment_policy']['inbox_id']).to eq(inbox.id)
          expect(json_response['inbox_assignment_policy']['assignment_policy']['id']).to eq(assignment_policy.id)
        end
      end

      context 'when inbox has no assignment policy' do
        it 'returns not found error' do
          get "/api/v1/accounts/#{account.id}/inboxes/#{inbox.id}/assignment_policy",
              headers: admin.create_new_auth_token,
              as: :json

          expect(response).to have_http_status(:not_found)
        end
      end
    end

    context 'when it is an agent with inbox access' do
      before do
        create(:inbox_member, inbox: inbox, user: agent)
      end

      it 'returns unauthorized (agents cannot view assignment policies)' do
        create(:inbox_assignment_policy, inbox: inbox, assignment_policy: assignment_policy)

        get "/api/v1/accounts/#{account.id}/inboxes/#{inbox.id}/assignment_policy",
            headers: agent.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an agent without inbox access' do
      it 'returns unauthorized' do
        get "/api/v1/accounts/#{account.id}/inboxes/#{inbox.id}/assignment_policy",
            headers: agent.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe 'POST /api/v1/accounts/{account.id}/assignment_policies/{assignment_policy_id}/inboxes' do
    let(:params) { { inbox_id: inbox.id } }

    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        post "/api/v1/accounts/#{account.id}/assignment_policies/#{assignment_policy.id}/inboxes",
             params: params

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated admin' do
      it 'creates the inbox assignment policy' do
        expect do
          post "/api/v1/accounts/#{account.id}/assignment_policies/#{assignment_policy.id}/inboxes",
               headers: admin.create_new_auth_token,
               params: params,
               as: :json
        end.to change(InboxAssignmentPolicy, :count).by(1)

        expect(response).to have_http_status(:created)
        json_response = response.parsed_body
        expect(json_response['inbox_assignment_policy']['inbox_id']).to eq(inbox.id)
        expect(json_response['inbox_assignment_policy']['assignment_policy']['id']).to eq(assignment_policy.id)
      end

      it 'replaces existing assignment if inbox already has one' do
        old_policy = create(:assignment_policy, account: account, name: 'Old Policy')
        create(:inbox_assignment_policy, inbox: inbox, assignment_policy: old_policy)

        expect do
          post "/api/v1/accounts/#{account.id}/assignment_policies/#{assignment_policy.id}/inboxes",
               headers: admin.create_new_auth_token,
               params: params,
               as: :json
        end.not_to change(InboxAssignmentPolicy, :count)

        expect(response).to have_http_status(:created)
        inbox.reload
        expect(inbox.assignment_policy).to eq(assignment_policy)
      end

      it 'returns error for invalid inbox_id' do
        invalid_params = { inbox_id: 0 }

        expect do
          post "/api/v1/accounts/#{account.id}/assignment_policies/#{assignment_policy.id}/inboxes",
               headers: admin.create_new_auth_token,
               params: invalid_params,
               as: :json
        end.not_to change(InboxAssignmentPolicy, :count)

        expect(response).to have_http_status(:not_found)
      end

      it 'returns error for inbox from different account' do
        other_account = create(:account)
        other_inbox = create(:inbox, account: other_account)
        invalid_params = { inbox_id: other_inbox.id }

        expect do
          post "/api/v1/accounts/#{account.id}/assignment_policies/#{assignment_policy.id}/inboxes",
               headers: admin.create_new_auth_token,
               params: invalid_params,
               as: :json
        end.not_to change(InboxAssignmentPolicy, :count)

        expect(response).to have_http_status(:not_found)
      end
    end

    context 'when it is an agent' do
      it 'returns unauthorized' do
        expect do
          post "/api/v1/accounts/#{account.id}/assignment_policies/#{assignment_policy.id}/inboxes",
               headers: agent.create_new_auth_token,
               params: params,
               as: :json
        end.not_to change(InboxAssignmentPolicy, :count)

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe 'DELETE /api/v1/accounts/{account.id}/assignment_policies/{assignment_policy_id}/inboxes/{inbox_id}' do
    before do
      create(:inbox_assignment_policy, inbox: inbox, assignment_policy: assignment_policy)
    end

    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        delete "/api/v1/accounts/#{account.id}/assignment_policies/#{assignment_policy.id}/inboxes/#{inbox.id}"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated admin' do
      it 'deletes the inbox assignment policy' do
        expect do
          delete "/api/v1/accounts/#{account.id}/assignment_policies/#{assignment_policy.id}/inboxes/#{inbox.id}",
                 headers: admin.create_new_auth_token,
                 as: :json
        end.to change(InboxAssignmentPolicy, :count).by(-1)

        expect(response).to have_http_status(:ok)
        expect(inbox.reload.assignment_policy).to be_nil
      end

      it 'returns not found if inbox is not assigned to the policy' do
        other_policy = create(:assignment_policy, account: account)

        expect do
          delete "/api/v1/accounts/#{account.id}/assignment_policies/#{other_policy.id}/inboxes/#{inbox.id}",
                 headers: admin.create_new_auth_token,
                 as: :json
        end.not_to change(InboxAssignmentPolicy, :count)

        expect(response).to have_http_status(:not_found)
      end

      it 'returns not found for non-existent inbox' do
        expect do
          delete "/api/v1/accounts/#{account.id}/assignment_policies/#{assignment_policy.id}/inboxes/0",
                 headers: admin.create_new_auth_token,
                 as: :json
        end.not_to change(InboxAssignmentPolicy, :count)

        expect(response).to have_http_status(:not_found)
      end
    end

    context 'when it is an agent' do
      it 'returns unauthorized' do
        expect do
          delete "/api/v1/accounts/#{account.id}/assignment_policies/#{assignment_policy.id}/inboxes/#{inbox.id}",
                 headers: agent.create_new_auth_token,
                 as: :json
        end.not_to change(InboxAssignmentPolicy, :count)

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe 'Edge cases and validations' do
    context 'when assignment policy belongs to different account' do
      let(:other_account) { create(:account) }
      let(:other_policy) { create(:assignment_policy, account: other_account) }

      it 'returns not found when trying to access' do
        get "/api/v1/accounts/#{account.id}/assignment_policies/#{other_policy.id}/inboxes",
            headers: admin.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:not_found)
      end
    end

    context 'when inbox belongs to different account' do
      let(:other_account) { create(:account) }
      let(:other_inbox) { create(:inbox, account: other_account) }

      it 'returns not found when trying to access' do
        get "/api/v1/accounts/#{account.id}/inboxes/#{other_inbox.id}/assignment_policy",
            headers: admin.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
