require 'rails_helper'

RSpec.describe 'Inbox Member API', type: :request do
  let(:account) { create(:account) }
  let(:inbox) { create(:inbox, account: account) }

  describe 'POST /api/v1/accounts/{account.id}/inbox_members' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        post "/api/v1/accounts/#{account.id}/inbox_members"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated agent' do
      let(:agent) { create(:user, account: account, role: :agent) }

      before do
        create(:inbox_member, user: agent, inbox: inbox)
      end

      it 'returns unauthorized' do
        params = { inbox_id: inbox.id, user_ids: [agent.id] }

        post "/api/v1/accounts/#{account.id}/inbox_members",
             headers: agent.create_new_auth_token,
             params: params,
             as: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user with access to inbox' do
      let(:administrator) { create(:user, account: account, role: :administrator) }
      let(:agent) { create(:user, account: account, role: :agent) }

      it 'modifies inbox members' do
        params = { inbox_id: inbox.id, user_ids: [agent.id] }

        post "/api/v1/accounts/#{account.id}/inbox_members",
             headers: administrator.create_new_auth_token,
             params: params,
             as: :json

        expect(response).to have_http_status(:success)
        expect(inbox.inbox_members&.count).to eq(1)
        expect(inbox.inbox_members&.first&.user).to eq(agent)
      end

      it 'renders not found when inbox not found' do
        params = { inbox_id: nil, user_ids: [agent.id] }

        post "/api/v1/accounts/#{account.id}/inbox_members",
             headers: administrator.create_new_auth_token,
             params: params,
             as: :json

        expect(response).to have_http_status(:not_found)
      end

      it 'renders error on invalid params' do
        params = { inbox_id: inbox.id, user_ids: ['invalid'] }

        post "/api/v1/accounts/#{account.id}/inbox_members",
             headers: administrator.create_new_auth_token,
             params: params,
             as: :json

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.body).to include('Could not add agents to inbox')
      end
    end
  end

  describe 'GET /api/v1/accounts/{account.id}/inbox_members/:id' do
    let(:inbox_member) { create(:inbox_member, inbox: inbox) }

    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get "/api/v1/accounts/#{account.id}/inbox_members/#{inbox_member.id}"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user with out access to inbox' do
      let(:agent) { create(:user, account: account, role: :agent) }

      it 'returns inbox member' do
        get "/api/v1/accounts/#{account.id}/inbox_members/#{inbox.id}",
            headers: agent.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user with access to inbox' do
      let(:agent) { create(:user, account: account, role: :agent) }

      it 'returns inbox member' do
        create(:inbox_member, user: agent, inbox: inbox)

        get "/api/v1/accounts/#{account.id}/inbox_members/#{inbox.id}",
            headers: agent.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        expect(JSON.parse(response.body)['payload'].pluck('id')).to eq(inbox.inbox_members.pluck(:user_id))
      end
    end
  end
end
