# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Assignment Policy API', type: :request do
  let!(:account) { create(:account) }
  let!(:assignment_policy) { create(:assignment_policy, account: account) }

  describe 'GET /api/v1/accounts/{account.id}/assignment_policies' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get "/api/v1/accounts/#{account.id}/assignment_policies"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      let(:admin) { create(:user, account: account, role: :administrator) }

      it 'returns all the assignment policies in account' do
        get "/api/v1/accounts/#{account.id}/assignment_policies",
            headers: admin.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        expect(response.body).to include(assignment_policy.name)
      end

      it 'returns assignment policies' do
        get "/api/v1/accounts/#{account.id}/assignment_policies",
            headers: admin.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        json_response = response.parsed_body
        expect(json_response['assignment_policies']).to be_an(Array)
        expect(json_response['assignment_policies'].first['id']).to eq(assignment_policy.id)
        expect(json_response['assignment_policies'].first['name']).to eq(assignment_policy.name)
        # Inboxes should NOT be included per review feedback
        expect(json_response['assignment_policies'].first).not_to have_key('inboxes')
      end
    end

    context 'when it is an agent' do
      let(:agent) { create(:user, account: account, role: :agent) }

      it 'returns unauthorized' do
        get "/api/v1/accounts/#{account.id}/assignment_policies",
            headers: agent.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe 'GET /api/v1/accounts/{account.id}/assignment_policies/:id' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get "/api/v1/accounts/#{account.id}/assignment_policies/#{assignment_policy.id}"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      let(:admin) { create(:user, account: account, role: :administrator) }

      it 'shows the assignment policy' do
        get "/api/v1/accounts/#{account.id}/assignment_policies/#{assignment_policy.id}",
            headers: admin.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        expect(response.body).to include(assignment_policy.name)
      end

      it 'returns 404 when assignment policy does not exist' do
        get "/api/v1/accounts/#{account.id}/assignment_policies/999999",
            headers: admin.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:not_found)
      end
    end

    context 'when it is an agent' do
      let(:agent) { create(:user, account: account, role: :agent) }

      it 'returns unauthorized' do
        get "/api/v1/accounts/#{account.id}/assignment_policies/#{assignment_policy.id}",
            headers: agent.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe 'POST /api/v1/accounts/{account.id}/assignment_policies' do
    let(:valid_params) do
      {
        assignment_policy: {
          name: 'New Policy',
          description: 'Test description',
          assignment_order: 'round_robin',
          conversation_priority: 'longest_waiting',
          fair_distribution_limit: 15,
          fair_distribution_window: 7200,
          enabled: true
        }
      }
    end

    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        expect { post "/api/v1/accounts/#{account.id}/assignment_policies", params: valid_params }.not_to change(AssignmentPolicy, :count)

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated admin' do
      let(:admin) { create(:user, account: account, role: :administrator) }

      it 'creates the assignment policy' do
        expect do
          post "/api/v1/accounts/#{account.id}/assignment_policies",
               headers: admin.create_new_auth_token,
               params: valid_params
        end.to change(AssignmentPolicy, :count).by(1)

        expect(response).to have_http_status(:created)
        json_response = response.parsed_body
        expect(json_response['assignment_policy']['name']).to eq('New Policy')
        expect(json_response['assignment_policy']['assignment_order']).to eq('round_robin')
      end

      it 'creates with minimal params' do
        minimal_params = { assignment_policy: { name: 'Minimal Policy' } }

        expect do
          post "/api/v1/accounts/#{account.id}/assignment_policies",
               headers: admin.create_new_auth_token,
               params: minimal_params
        end.to change(AssignmentPolicy, :count).by(1)

        expect(response).to have_http_status(:created)
      end

      it 'returns error for duplicate name' do
        create(:assignment_policy, account: account, name: 'Duplicate Name')
        duplicate_params = { assignment_policy: { name: 'Duplicate Name' } }

        expect do
          post "/api/v1/accounts/#{account.id}/assignment_policies",
               headers: admin.create_new_auth_token,
               params: duplicate_params
        end.not_to change(AssignmentPolicy, :count)

        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'returns error for invalid params' do
        invalid_params = { assignment_policy: { name: '' } }

        expect do
          post "/api/v1/accounts/#{account.id}/assignment_policies",
               headers: admin.create_new_auth_token,
               params: invalid_params
        end.not_to change(AssignmentPolicy, :count)

        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context 'when it is an agent' do
      let(:agent) { create(:user, account: account, role: :agent) }

      it 'returns unauthorized' do
        expect do
          post "/api/v1/accounts/#{account.id}/assignment_policies",
               headers: agent.create_new_auth_token,
               params: valid_params
        end.not_to change(AssignmentPolicy, :count)

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe 'PUT /api/v1/accounts/{account.id}/assignment_policies/:id' do
    let(:valid_params) do
      {
        assignment_policy: {
          name: 'Updated Policy',
          assignment_order: 'round_robin',
          fair_distribution_limit: 20
        }
      }
    end

    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        put "/api/v1/accounts/#{account.id}/assignment_policies/#{assignment_policy.id}",
            params: valid_params

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated admin' do
      let(:admin) { create(:user, account: account, role: :administrator) }

      it 'updates the assignment policy' do
        put "/api/v1/accounts/#{account.id}/assignment_policies/#{assignment_policy.id}",
            headers: admin.create_new_auth_token,
            params: valid_params,
            as: :json

        expect(response).to have_http_status(:success)
        assignment_policy.reload
        expect(assignment_policy.name).to eq('Updated Policy')
        expect(assignment_policy.assignment_order).to eq('round_robin')
        expect(assignment_policy.fair_distribution_limit).to eq(20)
      end

      it 'updates partial params' do
        partial_params = { assignment_policy: { enabled: false } }

        put "/api/v1/accounts/#{account.id}/assignment_policies/#{assignment_policy.id}",
            headers: admin.create_new_auth_token,
            params: partial_params,
            as: :json

        expect(response).to have_http_status(:success)
        expect(assignment_policy.reload.enabled).to be(false)
      end

      it 'returns error for duplicate name' do
        create(:assignment_policy, account: account, name: 'Another Policy')
        duplicate_params = { assignment_policy: { name: 'Another Policy' } }

        put "/api/v1/accounts/#{account.id}/assignment_policies/#{assignment_policy.id}",
            headers: admin.create_new_auth_token,
            params: duplicate_params,
            as: :json

        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'returns 404 when assignment policy does not exist' do
        put "/api/v1/accounts/#{account.id}/assignment_policies/999999",
            headers: admin.create_new_auth_token,
            params: valid_params,
            as: :json

        expect(response).to have_http_status(:not_found)
      end
    end

    context 'when it is an agent' do
      let(:agent) { create(:user, account: account, role: :agent) }

      it 'returns unauthorized' do
        put "/api/v1/accounts/#{account.id}/assignment_policies/#{assignment_policy.id}",
            headers: agent.create_new_auth_token,
            params: valid_params,
            as: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe 'DELETE /api/v1/accounts/{account.id}/assignment_policies/:id' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        delete "/api/v1/accounts/#{account.id}/assignment_policies/#{assignment_policy.id}"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated admin' do
      let(:admin) { create(:user, account: account, role: :administrator) }

      it 'deletes the assignment policy' do
        expect do
          delete "/api/v1/accounts/#{account.id}/assignment_policies/#{assignment_policy.id}",
                 headers: admin.create_new_auth_token,
                 as: :json
        end.to change(AssignmentPolicy, :count).by(-1)

        expect(response).to have_http_status(:ok)
      end

      it 'deletes associated inbox_assignment_policies' do
        inbox = create(:inbox, account: account)
        create(:inbox_assignment_policy, inbox: inbox, assignment_policy: assignment_policy)

        expect do
          delete "/api/v1/accounts/#{account.id}/assignment_policies/#{assignment_policy.id}",
                 headers: admin.create_new_auth_token,
                 as: :json
        end.to change(InboxAssignmentPolicy, :count).by(-1)

        expect(response).to have_http_status(:ok)
      end

      it 'returns 404 when assignment policy does not exist' do
        delete "/api/v1/accounts/#{account.id}/assignment_policies/999999",
               headers: admin.create_new_auth_token,
               as: :json

        expect(response).to have_http_status(:not_found)
      end
    end

    context 'when it is an agent' do
      let(:agent) { create(:user, account: account, role: :agent) }

      it 'returns unauthorized' do
        expect do
          delete "/api/v1/accounts/#{account.id}/assignment_policies/#{assignment_policy.id}",
                 headers: agent.create_new_auth_token,
                 as: :json
        end.not_to change(AssignmentPolicy, :count)

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end
