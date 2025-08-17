require 'rails_helper'

RSpec.describe 'Assignment Policies API - Enterprise Features', type: :request do
  let(:account) { create(:account) }
  let(:admin) { create(:user, account: account, role: :administrator) }

  describe 'balanced assignment order (Enterprise Feature)' do
    describe 'POST /api/v1/accounts/{account.id}/assignment_policies' do
      it 'creates assignment policy with balanced order' do
        params = {
          assignment_policy: {
            name: 'Enterprise Policy',
            description: 'Policy with balanced assignment',
            assignment_order: 'balanced',
            conversation_priority: 'longest_waiting',
            fair_distribution_limit: 20
          }
        }

        post "/api/v1/accounts/#{account.id}/assignment_policies",
             headers: admin.create_new_auth_token,
             params: params,
             as: :json

        expect(response).to have_http_status(:success)
        json_response = response.parsed_body
        expect(json_response['assignment_order']).to eq('balanced')
      end

      it 'defaults to round_robin when invalid assignment_order provided' do
        params = {
          assignment_policy: {
            name: 'Test Policy',
            assignment_order: 'invalid_order'
          }
        }

        post "/api/v1/accounts/#{account.id}/assignment_policies",
             headers: admin.create_new_auth_token,
             params: params,
             as: :json

        expect(response).to have_http_status(:success)
        json_response = response.parsed_body
        expect(json_response['assignment_order']).to eq('round_robin')
      end
    end

    describe 'PUT /api/v1/accounts/{account.id}/assignment_policies/:id' do
      let(:assignment_policy) { create(:assignment_policy, account: account, assignment_order: 'round_robin') }

      it 'updates assignment policy to balanced order' do
        params = {
          assignment_policy: {
            assignment_order: 'balanced'
          }
        }

        put "/api/v1/accounts/#{account.id}/assignment_policies/#{assignment_policy.id}",
            headers: admin.create_new_auth_token,
            params: params,
            as: :json

        expect(response).to have_http_status(:success)
        assignment_policy.reload
        expect(assignment_policy.assignment_order).to eq('balanced')
      end

      it 'updates from balanced back to round_robin' do
        assignment_policy.update!(assignment_order: 'balanced')
        params = {
          assignment_policy: {
            assignment_order: 'round_robin'
          }
        }

        put "/api/v1/accounts/#{account.id}/assignment_policies/#{assignment_policy.id}",
            headers: admin.create_new_auth_token,
            params: params,
            as: :json

        expect(response).to have_http_status(:success)
        assignment_policy.reload
        expect(assignment_policy.assignment_order).to eq('round_robin')
      end
    end

    describe 'GET /api/v1/accounts/{account.id}/assignment_policies' do
      before do
        create(:assignment_policy, account: account, name: 'Round Robin Policy', assignment_order: 'round_robin')
        create(:assignment_policy, account: account, name: 'Balanced Policy', assignment_order: 'balanced')
      end

      it 'returns policies with correct assignment orders' do
        get "/api/v1/accounts/#{account.id}/assignment_policies",
            headers: admin.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        json_response = response.parsed_body
        expect(json_response.length).to eq(2)

        balanced_policy = json_response.find { |p| p['name'] == 'Balanced Policy' }
        round_robin_policy = json_response.find { |p| p['name'] == 'Round Robin Policy' }

        expect(balanced_policy['assignment_order']).to eq('balanced')
        expect(round_robin_policy['assignment_order']).to eq('round_robin')
      end
    end

    describe 'GET /api/v1/accounts/{account.id}/assignment_policies/:id' do
      let(:balanced_policy) { create(:assignment_policy, account: account, assignment_order: 'balanced') }

      it 'shows assignment policy with balanced order' do
        get "/api/v1/accounts/#{account.id}/assignment_policies/#{balanced_policy.id}",
            headers: admin.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        json_response = response.parsed_body
        expect(json_response['assignment_order']).to eq('balanced')
      end
    end
  end
end
