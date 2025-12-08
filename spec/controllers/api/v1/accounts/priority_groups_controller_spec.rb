require 'rails_helper'

RSpec.describe 'PriorityGroups API', type: :request do
  let(:account) { create(:account) }
  let(:agent) { create(:user, account: account, role: :agent) }
  let(:admin) { create(:user, account: account, role: :administrator) }

  describe 'GET /api/v1/accounts/{account.id}/priority_groups' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get "/api/v1/accounts/#{account.id}/priority_groups"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      let(:priority_group1) { create(:priority_group, account: account, name: 'High') }
      let(:priority_group2) { create(:priority_group, account: account, name: 'Low') }

      before do
        priority_group1
        priority_group2
      end

      it 'returns all priority groups for agent' do
        get "/api/v1/accounts/#{account.id}/priority_groups",
            headers: agent.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        data = response.parsed_body
        expect(data.map { |pg| pg['name'] }).to match_array(%w[High Low])
      end

      it 'returns all priority groups for administrator' do
        get "/api/v1/accounts/#{account.id}/priority_groups",
            headers: admin.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        json_response = response.parsed_body
        expect(json_response.size).to eq(2)
        expect(json_response.map { |pg| pg['name'] }).to match_array(%w[High Low])
      end

      it 'returns only id and name for each priority group' do
        get "/api/v1/accounts/#{account.id}/priority_groups",
            headers: admin.create_new_auth_token,
            as: :json

        json_response = response.parsed_body
        expect(json_response.first.keys).to match_array(%w[id name])
      end
    end
  end
end
