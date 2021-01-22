require 'rails_helper'

RSpec.describe 'Team Members API', type: :request do
  let(:account) { create(:account) }
  let!(:team) { create(:team, account: account) }

  describe 'GET /api/v1/accounts/{account.id}/teams/{team_id}/team_members' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get "/api/v1/accounts/#{account.id}/teams/#{team.id}/team_members"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      let(:agent) { create(:user, account: account, role: :agent) }

      it 'returns all the teams' do
        create(:team_member, team: team, user: agent)
        get "/api/v1/accounts/#{account.id}/teams/#{team.id}/team_members",
            headers: agent.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        expect(JSON.parse(response.body).first['id']).to eq(agent.id)
      end
    end
  end

  describe 'POST /api/v1/accounts/{account.id}/teams/{team_id}/team_members' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        post "/api/v1/accounts/#{account.id}/teams/#{team.id}/team_members"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      let(:agent) { create(:user, account: account, role: :agent) }
      let(:administrator) { create(:user, account: account, role: :administrator) }

      it 'returns unathorized for agent' do
        params = { user_id: agent.id }

        post "/api/v1/accounts/#{account.id}/teams/#{team.id}/team_members",
             params: params,
             headers: agent.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:unauthorized)
      end

      it 'add a new team member when its administrator' do
        params = { user_id: agent.id }

        post "/api/v1/accounts/#{account.id}/teams/#{team.id}/team_members",
             params: params,
             headers: administrator.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:success)
        json_response = JSON.parse(response.body)
        expect(json_response['id']).to eq(agent.id)
      end
    end
  end

  describe 'DELETE /api/v1/accounts/{account.id}/teams/{team_id}/team_members' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        delete "/api/v1/accounts/#{account.id}/teams/#{team.id}/team_members"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      let(:agent) { create(:user, account: account, role: :agent) }
      let(:administrator) { create(:user, account: account, role: :administrator) }

      it 'return unauthorized for agent' do
        params = { user_id: agent.id }
        delete "/api/v1/accounts/#{account.id}/teams/#{team.id}/team_members",
               params: params,
               headers: agent.create_new_auth_token,
               as: :json

        expect(response).to have_http_status(:unauthorized)
      end

      it 'destroys the team member when its administrator' do
        params = { user_id: agent.id }
        create(:team_member, team: team, user: agent)
        delete "/api/v1/accounts/#{account.id}/teams/#{team.id}",
               params: params,
               headers: administrator.create_new_auth_token,
               as: :json

        expect(response).to have_http_status(:success)
        expect(team.team_members.count).to eq(0)
      end
    end
  end
end
