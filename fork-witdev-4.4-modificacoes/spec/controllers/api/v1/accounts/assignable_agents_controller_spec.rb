require 'rails_helper'

RSpec.describe 'Assignable Agents API', type: :request do
  let(:account) { create(:account) }
  let(:agent1) { create(:user, account: account, role: :agent) }
  let!(:agent2) { create(:user, account: account, role: :agent) }
  let!(:admin) { create(:user, account: account, role: :administrator) }

  describe 'GET /api/v1/accounts/{account.id}/assignable_agents' do
    let(:inbox1) { create(:inbox, account: account) }
    let(:inbox2) { create(:inbox, account: account) }

    before do
      create(:inbox_member, user: agent1, inbox: inbox1)
      create(:inbox_member, user: agent1, inbox: inbox2)
    end

    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get "/api/v1/accounts/#{account.id}/assignable_agents"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when the user is not part of an inbox' do
      context 'when the user is an admininstrator' do
        it 'returns all assignable inbox members along with administrators' do
          get "/api/v1/accounts/#{account.id}/assignable_agents",
              params: { inbox_ids: [inbox1.id, inbox2.id] },
              headers: admin.create_new_auth_token,
              as: :json

          expect(response).to have_http_status(:success)
          response_data = JSON.parse(response.body, symbolize_names: true)[:payload]
          expect(response_data.size).to eq(2)
          expect(response_data.pluck(:role)).to include('agent', 'administrator')
        end
      end

      context 'when the user is an agent' do
        it 'returns unauthorized' do
          get "/api/v1/accounts/#{account.id}/assignable_agents",
              params: { inbox_ids: [inbox1.id, inbox2.id] },
              headers: agent2.create_new_auth_token,
              as: :json

          expect(response).to have_http_status(:unauthorized)
        end
      end
    end

    context 'when the user is part of the inbox' do
      it 'returns all assignable inbox members along with administrators' do
        get "/api/v1/accounts/#{account.id}/assignable_agents",
            params: { inbox_ids: [inbox1.id, inbox2.id] },
            headers: agent1.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        response_data = JSON.parse(response.body, symbolize_names: true)[:payload]
        expect(response_data.size).to eq(2)
        expect(response_data.pluck(:role)).to include('agent', 'administrator')
      end
    end
  end
end
