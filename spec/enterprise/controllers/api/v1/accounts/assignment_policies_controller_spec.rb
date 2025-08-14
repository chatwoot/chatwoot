# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Assignment Policy API - Enterprise', type: :request do
  let!(:account) { create(:account) }
  let!(:admin) { create(:user, account: account, role: :administrator) }

  describe 'balanced assignment order (Enterprise Feature)' do
    context 'when creating assignment policies' do
      it 'allows creating assignment policy with balanced order' do
        params = {
          assignment_policy: {
            name: 'Enterprise Policy',
            description: 'Policy with balanced assignment',
            assignment_order: 'balanced',
            conversation_priority: 'longest_waiting',
            fair_distribution_limit: 20,
            fair_distribution_window: 3600
          }
        }

        post "/api/v1/accounts/#{account.id}/assignment_policies",
             headers: admin.create_new_auth_token,
             params: params,
             as: :json

        expect(response).to have_http_status(:created)
        json_response = response.parsed_body
        expect(json_response['assignment_policy']['assignment_order']).to eq('balanced')
      end
    end

    context 'when updating assignment policies' do
      let!(:assignment_policy) { create(:assignment_policy, account: account, assignment_order: 'round_robin') }

      it 'allows updating assignment policy to balanced order' do
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
    end

    context 'when fetching assignment policies' do
      let(:balanced_policy) { create(:assignment_policy, account: account, name: 'Balanced Policy', assignment_order: 'balanced') }
      let(:round_robin_policy) { create(:assignment_policy, account: account, name: 'Round Robin Policy', assignment_order: 'round_robin') }

      before do
        round_robin_policy
        balanced_policy
      end

      it 'returns policies with balanced assignment order' do
        get "/api/v1/accounts/#{account.id}/assignment_policies",
            headers: admin.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        json_response = response.parsed_body

        balanced_entry = json_response['assignment_policies'].find { |p| p['id'] == balanced_policy.id }
        expect(balanced_entry['assignment_order']).to eq('balanced')
      end
    end
  end
end
