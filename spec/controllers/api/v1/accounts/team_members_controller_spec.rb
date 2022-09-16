require 'rails_helper'

RSpec.describe 'Team Members API', type: :request do
  let(:account) { create(:account) }
  let(:account_2) { create(:account) }
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

      it 'add a new team members when its administrator' do
        user_ids = (1..5).map { create(:user, account: account, role: :agent).id }
        params = { user_ids: user_ids }
        # have a team member added already
        create(:team_member, team: team, user: User.find(user_ids.first))

        post "/api/v1/accounts/#{account.id}/teams/#{team.id}/team_members",
             params: params,
             headers: administrator.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:success)
        json_response = JSON.parse(response.body)
        expect(json_response.count).to eq(user_ids.count - 1)
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

      it 'destroys the team members when its administrator' do
        user_ids = (1..5).map { create(:user, account: account, role: :agent).id }
        user_ids.each { |id| create(:team_member, team: team, user: User.find(id)) }
        params = { user_ids: user_ids.first(3) }

        delete "/api/v1/accounts/#{account.id}/teams/#{team.id}/team_members",
               params: params,
               headers: administrator.create_new_auth_token,
               as: :json

        expect(response).to have_http_status(:success)
        expect(team.team_members.count).to eq(2)
      end
    end
  end

  describe 'PATCH /api/v1/accounts/{account.id}/teams/{team_id}/team_members' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        patch "/api/v1/accounts/#{account.id}/teams/#{team.id}/team_members"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      let(:agent) { create(:user, account: account, role: :agent) }
      let(:agent_2) { create(:user, account: account_2, role: :agent) }
      let(:administrator) { create(:user, account: account, role: :administrator) }

      it 'return unauthorized for agent' do
        params = { user_id: agent.id }
        patch "/api/v1/accounts/#{account.id}/teams/#{team.id}/team_members",
              params: params,
              headers: agent.create_new_auth_token,
              as: :json

        expect(response).to have_http_status(:unauthorized)
      end

      it 'updates the team members when its administrator' do
        user_ids = (1..5).map { create(:user, account: account, role: :agent).id }
        params = { user_ids: user_ids }

        patch "/api/v1/accounts/#{account.id}/teams/#{team.id}/team_members",
              params: params,
              headers: administrator.create_new_auth_token,
              as: :json

        expect(response).to have_http_status(:success)
        json_response = JSON.parse(response.body)
        expect(json_response.count).to eq(user_ids.count)
      end

      it 'ignores the user ids when its not a valid account user id' do
        params = { user_ids: [agent_2.id] }

        patch "/api/v1/accounts/#{account.id}/teams/#{team.id}/team_members",
              params: params,
              headers: administrator.create_new_auth_token,
              as: :json

        expect(response).to have_http_status(:unauthorized)
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to eq('Invalid User IDs')
      end
    end
  end
end
