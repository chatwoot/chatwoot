require 'rails_helper'

RSpec.describe 'Assignment Policies API', type: :request do
  let(:account) { create(:account) }

  describe 'GET /api/v1/accounts/{account.id}/assignment_policies' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get "/api/v1/accounts/#{account.id}/assignment_policies"
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated admin' do
      let(:admin) { create(:user, account: account, role: :administrator) }

      before do
        create_list(:assignment_policy, 3, account: account)
      end

      it 'returns all assignment policies for the account' do
        get "/api/v1/accounts/#{account.id}/assignment_policies",
            headers: admin.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        json_response = response.parsed_body
        expect(json_response.length).to eq(3)
        expect(json_response.first.keys).to include('id', 'name', 'description')
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
    let(:assignment_policy) { create(:assignment_policy, account: account) }

    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get "/api/v1/accounts/#{account.id}/assignment_policies/#{assignment_policy.id}"
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated admin' do
      let(:admin) { create(:user, account: account, role: :administrator) }

      it 'returns the assignment policy' do
        get "/api/v1/accounts/#{account.id}/assignment_policies/#{assignment_policy.id}",
            headers: admin.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        json_response = response.parsed_body
        expect(json_response['id']).to eq(assignment_policy.id)
        expect(json_response['name']).to eq(assignment_policy.name)
      end

      it 'returns not found for non-existent policy' do
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
          name: 'New Assignment Policy',
          description: 'Policy for new team',
          conversation_priority: 'longest_waiting',
          fair_distribution_limit: 15,
          enabled: true
        }
      }
    end

    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        post "/api/v1/accounts/#{account.id}/assignment_policies", params: valid_params
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated admin' do
      let(:admin) { create(:user, account: account, role: :administrator) }

      it 'creates a new assignment policy' do
        expect do
          post "/api/v1/accounts/#{account.id}/assignment_policies",
               headers: admin.create_new_auth_token,
               params: valid_params,
               as: :json
        end.to change(AssignmentPolicy, :count).by(1)

        expect(response).to have_http_status(:success)
        json_response = response.parsed_body
        expect(json_response['name']).to eq('New Assignment Policy')
        expect(json_response['conversation_priority']).to eq('longest_waiting')
      end

      it 'creates policy with minimal required params' do
        minimal_params = { assignment_policy: { name: 'Minimal Policy' } }

        expect do
          post "/api/v1/accounts/#{account.id}/assignment_policies",
               headers: admin.create_new_auth_token,
               params: minimal_params,
               as: :json
        end.to change(AssignmentPolicy, :count).by(1)

        expect(response).to have_http_status(:success)
      end

      it 'prevents duplicate policy names within account' do
        create(:assignment_policy, account: account, name: 'Duplicate Policy')
        duplicate_params = { assignment_policy: { name: 'Duplicate Policy' } }

        expect do
          post "/api/v1/accounts/#{account.id}/assignment_policies",
               headers: admin.create_new_auth_token,
               params: duplicate_params,
               as: :json
        end.not_to change(AssignmentPolicy, :count)

        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'validates required fields' do
        invalid_params = { assignment_policy: { name: '' } }

        post "/api/v1/accounts/#{account.id}/assignment_policies",
             headers: admin.create_new_auth_token,
             params: invalid_params,
             as: :json

        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context 'when it is an agent' do
      let(:agent) { create(:user, account: account, role: :agent) }

      it 'returns unauthorized' do
        post "/api/v1/accounts/#{account.id}/assignment_policies",
             headers: agent.create_new_auth_token,
             params: valid_params,
             as: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe 'PUT /api/v1/accounts/{account.id}/assignment_policies/:id' do
    let(:assignment_policy) { create(:assignment_policy, account: account, name: 'Original Policy') }
    let(:update_params) do
      {
        assignment_policy: {
          name: 'Updated Policy',
          description: 'Updated description',
          fair_distribution_limit: 20
        }
      }
    end

    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        put "/api/v1/accounts/#{account.id}/assignment_policies/#{assignment_policy.id}",
            params: update_params

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated admin' do
      let(:admin) { create(:user, account: account, role: :administrator) }

      it 'updates the assignment policy' do
        put "/api/v1/accounts/#{account.id}/assignment_policies/#{assignment_policy.id}",
            headers: admin.create_new_auth_token,
            params: update_params,
            as: :json

        expect(response).to have_http_status(:success)
        assignment_policy.reload
        expect(assignment_policy.name).to eq('Updated Policy')
        expect(assignment_policy.fair_distribution_limit).to eq(20)
      end

      it 'allows partial updates' do
        partial_params = { assignment_policy: { enabled: false } }

        put "/api/v1/accounts/#{account.id}/assignment_policies/#{assignment_policy.id}",
            headers: admin.create_new_auth_token,
            params: partial_params,
            as: :json

        expect(response).to have_http_status(:success)
        expect(assignment_policy.reload.enabled).to be(false)
        expect(assignment_policy.name).to eq('Original Policy') # unchanged
      end

      it 'prevents duplicate names during update' do
        create(:assignment_policy, account: account, name: 'Existing Policy')
        duplicate_params = { assignment_policy: { name: 'Existing Policy' } }

        put "/api/v1/accounts/#{account.id}/assignment_policies/#{assignment_policy.id}",
            headers: admin.create_new_auth_token,
            params: duplicate_params,
            as: :json

        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'returns not found for non-existent policy' do
        put "/api/v1/accounts/#{account.id}/assignment_policies/999999",
            headers: admin.create_new_auth_token,
            params: update_params,
            as: :json

        expect(response).to have_http_status(:not_found)
      end
    end

    context 'when it is an agent' do
      let(:agent) { create(:user, account: account, role: :agent) }

      it 'returns unauthorized' do
        put "/api/v1/accounts/#{account.id}/assignment_policies/#{assignment_policy.id}",
            headers: agent.create_new_auth_token,
            params: update_params,
            as: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe 'DELETE /api/v1/accounts/{account.id}/assignment_policies/:id' do
    let(:assignment_policy) { create(:assignment_policy, account: account) }

    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        delete "/api/v1/accounts/#{account.id}/assignment_policies/#{assignment_policy.id}"
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated admin' do
      let(:admin) { create(:user, account: account, role: :administrator) }

      it 'deletes the assignment policy' do
        assignment_policy # create it first

        expect do
          delete "/api/v1/accounts/#{account.id}/assignment_policies/#{assignment_policy.id}",
                 headers: admin.create_new_auth_token,
                 as: :json
        end.to change(AssignmentPolicy, :count).by(-1)

        expect(response).to have_http_status(:ok)
      end

      it 'cascades deletion to associated inbox assignment policies' do
        inbox = create(:inbox, account: account)
        create(:inbox_assignment_policy, inbox: inbox, assignment_policy: assignment_policy)

        expect do
          delete "/api/v1/accounts/#{account.id}/assignment_policies/#{assignment_policy.id}",
                 headers: admin.create_new_auth_token,
                 as: :json
        end.to change(InboxAssignmentPolicy, :count).by(-1)

        expect(response).to have_http_status(:ok)
      end

      it 'returns not found for non-existent policy' do
        delete "/api/v1/accounts/#{account.id}/assignment_policies/999999",
               headers: admin.create_new_auth_token,
               as: :json

        expect(response).to have_http_status(:not_found)
      end
    end

    context 'when it is an agent' do
      let(:agent) { create(:user, account: account, role: :agent) }

      it 'returns unauthorized' do
        delete "/api/v1/accounts/#{account.id}/assignment_policies/#{assignment_policy.id}",
               headers: agent.create_new_auth_token,
               as: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end
