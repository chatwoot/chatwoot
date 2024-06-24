require 'rails_helper'

RSpec.describe 'Inbox Teams API', type: :request do
  # create method of FactoryBot will create a resource directly in database
  # let is an method of RSPEC that returns the same resource in other tests cases
  let(:account) { create(:account) }
  let(:inbox) { create(:inbox, account: account) }

  describe 'GET /api/v1/accounts/{account.id}/inbox_teams/:id' do
    context 'when it is an unauthenticated user' do
      it 'return unauthorized' do
        get "/api/v1/accounts/#{account.id}/inbox_teams/#{inbox.id}"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user with out access to inbox' do
      let(:agent) { create(:user, account: account, role: :agent) }

      it 'return unauthorized' do
        get "/api/v1/accounts/#{account.id}/inbox_teams/#{inbox.id}",
            headers: agent.create_new_auth_token,
            as: :json
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user with access to inbox' do
      let(:team) { create(:team, account: account) } # ! -> Database creation operation is executed immediately
      let(:agent) { create(:user, account: account, role: :agent) }

      it 'returns inbox team' do
        create(:team_member, user: agent, team: team)
        create(:inbox_team, inbox: inbox, team: team)
        get "/api/v1/accounts/#{account.id}/inbox_teams/#{inbox.id}",
            headers: agent.create_new_auth_token,
            as: :json
        expect(response).to have_http_status(:success)
        expect(response.parsed_body['payload'].pluck('id')).to eq(inbox.inbox_teams.pluck(:team_id))
        # byebug
      end
    end
  end

  describe 'POST /api/v1/accounts/{account.id}/inbox_teams/' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        post "/api/v1/accounts/#{account.id}/inbox_teams"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated agent' do
      let(:team) { create(:team, account: account) }
      let(:agent) { create(:user, account: account, role: :agent) }

      before do
        create(:inbox_team, inbox: inbox, team: team)
      end

      it 'returns unauthorized' do
        params = { inbox_id: inbox.id, team_ids: [team.id] }

        post "/api/v1/accounts/#{account.id}/inbox_teams",
             headers: agent.create_new_auth_token,
             params: params,
             as: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an administrator' do
      let(:administrator) { create(:user, account: account, role: :administrator) }
      let(:old_team) { create(:team, account: account, name: 'Old team') }
      let(:team_to_add) { create(:team, account: account, name: 'Team to add') }

      before do
        create(:inbox_team, inbox: inbox, team: old_team)
      end

      it 'add inbox teams' do
        params = { inbox_id: inbox.id, team_ids: [old_team.id, team_to_add.id] }

        post "/api/v1/accounts/#{account.id}/inbox_teams",
             headers: administrator.create_new_auth_token,
             params: params,
             as: :json
        expect(response).to have_http_status(:success)
        expect(inbox.inbox_teams&.count).to eq(2)
        expect(inbox.inbox_teams&.second&.team).to eq(team_to_add)
      end

      it 'renders not found when inbox not found' do
        params = { inbox_id: nil, team_ids: [team_to_add.id] }

        post "/api/v1/accounts/#{account.id}/inbox_teams",
             headers: administrator.create_new_auth_token,
             params: params,
             as: :json

        expect(response).to have_http_status(:not_found)
      end

      it 'renders error on invalid params' do
        params = { inbox_id: inbox.id, team_ids: ['invalid'] }

        post "/api/v1/accounts/#{account.id}/inbox_teams",
             headers: administrator.create_new_auth_token,
             params: params,
             as: :json

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.body).to include('Team must exist')
      end
    end
  end

  describe 'PATCH /api/v1/accounts/{account.id}/inbox_teams' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        patch "/api/v1/accounts/#{account.id}/inbox_teams"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated agent' do
      let(:team) { create(:team, account: account) }
      let(:agent) { create(:user, account: account, role: :agent) }

      before do
        create(:inbox_team, inbox: inbox, team: team)
      end

      it 'returns unauthorized' do
        params = { inbox_id: inbox.id, team_ids: [team.id] }

        patch "/api/v1/accounts/#{account.id}/inbox_teams",
              headers: agent.create_new_auth_token,
              params: params,
              as: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an administrator' do
      let(:administrator) { create(:user, account: account, role: :administrator) }
      let(:old_team) { create(:team, account: account, name: 'Old teams') }
      let(:team_to_add) { create(:team, account: account, name: 'New teams') }

      before do
        create(:inbox_team, inbox: inbox, team: old_team)
      end

      it 'modifies inbox teams' do
        params = { inbox_id: inbox.id, team_ids: [team_to_add.id] }

        patch "/api/v1/accounts/#{account.id}/inbox_teams",
              headers: administrator.create_new_auth_token,
              params: params,
              as: :json
        expect(response).to have_http_status(:success)
        expect(inbox.inbox_teams&.count).to eq(1)
        expect(inbox.inbox_teams&.first&.team).to eq(team_to_add)
      end

      it 'renders not found when inbox not found' do
        params = { inbox_id: nil, team_ids: [team_to_add.id] }

        patch "/api/v1/accounts/#{account.id}/inbox_teams",
              headers: administrator.create_new_auth_token,
              params: params,
              as: :json

        expect(response).to have_http_status(:not_found)
      end

      it 'renders error on invalid params' do
        params = { inbox_id: inbox.id, team_ids: ['invalid'] }

        patch "/api/v1/accounts/#{account.id}/inbox_teams",
              headers: administrator.create_new_auth_token,
              params: params,
              as: :json

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.body).to include('Team must exist')
      end
    end
  end

  describe 'DELETE /api/v1/account/{account.id}/inbox_teams' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        patch "/api/v1/accounts/#{account.id}/inbox_teams"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated agent' do
      let(:team) { create(:team, account: account) }
      let(:agent) { create(:user, account: account, role: :agent) }

      it 'returns unauthorized' do
        params = { inbox_id: inbox.id, team_ids: [team.id] }

        delete "/api/v1/accounts/#{account.id}/inbox_teams",
               headers: agent.create_new_auth_token,
               params: params,
               as: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an administrator' do
      let(:administrator) { create(:user, account: account, role: :administrator) }
      let(:old_team) { create(:team, account: account, name: 'Old team') }
      let(:team_to_delete) { create(:team, account: account, name: 'Team to delete') }
      let(:non_inbox_team) { create(:team, account: account, name: 'Non inbox team') }

      before do
        create(:inbox_team, inbox: inbox, team: old_team)
        create(:inbox_team, inbox: inbox, team: team_to_delete)
      end

      it 'delete inbox teams' do
        params = { inbox_id: inbox.id, team_ids: [team_to_delete.id] }

        delete "/api/v1/accounts/#{account.id}/inbox_teams",
               headers: administrator.create_new_auth_token,
               params: params,
               as: :json
        expect(response).to have_http_status(:success)
        expect(inbox.inbox_teams&.count).to eq(1)
      end

      it 'renders not found when inbox not found' do
        params = { inbox_id: nil, team_ids: [team_to_delete.id] }

        delete "/api/v1/accounts/#{account.id}/inbox_teams",
               headers: administrator.create_new_auth_token,
               params: params,
               as: :json

        expect(response).to have_http_status(:not_found)
      end

      it 'renders error on invalid params' do
        params = { inbox_id: inbox.id, team_ids: ['invalid'] }

        delete "/api/v1/accounts/#{account.id}/inbox_teams",
               headers: administrator.create_new_auth_token,
               params: params,
               as: :json

        expect(response).to have_http_status(:not_found)
        expect(response.body).to include('Resource could not be found')
      end

      it 'renders error on non member params' do
        params = { inbox_id: inbox.id, team_ids: [non_inbox_team.id] }

        delete "/api/v1/accounts/#{account.id}/inbox_teams",
               headers: administrator.create_new_auth_token,
               params: params,
               as: :json

        expect(response).to have_http_status(:not_found)
        expect(response.body).to include('Resource could not be found')
      end
    end
  end
end
