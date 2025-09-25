require 'rails_helper'

RSpec.describe 'Inbox Member API', type: :request do
  let(:account) { create(:account) }
  let(:inbox) { create(:inbox, account: account) }

  describe 'GET /api/v1/accounts/{account.id}/inbox_members/:id' do
    let(:inbox_member) { create(:inbox_member, inbox: inbox) }

    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get "/api/v1/accounts/#{account.id}/inbox_members/#{inbox.id}"

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
        expect(response.parsed_body['payload'].pluck('id')).to eq(inbox.inbox_members.pluck(:user_id))
      end
    end
  end

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

    context 'when it is an administrator' do
      let(:administrator) { create(:user, account: account, role: :administrator) }
      let(:old_agent) { create(:user, account: account, role: :agent) }
      let(:agent_to_add) { create(:user, account: account, role: :agent) }

      before do
        create(:inbox_member, user: old_agent, inbox: inbox)
      end

      it 'add inbox members' do
        params = { inbox_id: inbox.id, user_ids: [old_agent.id, agent_to_add.id] }

        post "/api/v1/accounts/#{account.id}/inbox_members",
             headers: administrator.create_new_auth_token,
             params: params,
             as: :json

        expect(response).to have_http_status(:success)
        expect(inbox.inbox_members&.count).to eq(2)
        expect(inbox.inbox_members&.second&.user).to eq(agent_to_add)
      end

      it 'renders not found when inbox not found' do
        params = { inbox_id: nil, user_ids: [agent_to_add.id] }

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
        expect(response.body).to include('User must exist')
      end
    end
  end

  describe 'PATCH /api/v1/accounts/{account.id}/inbox_members' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        patch "/api/v1/accounts/#{account.id}/inbox_members"

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

        patch "/api/v1/accounts/#{account.id}/inbox_members",
              headers: agent.create_new_auth_token,
              params: params,
              as: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an administrator' do
      let(:administrator) { create(:user, account: account, role: :administrator) }
      let(:old_agent) { create(:user, account: account, role: :agent) }
      let(:agent_to_add) { create(:user, account: account, role: :agent) }

      before do
        create(:inbox_member, user: old_agent, inbox: inbox)
      end

      it 'modifies inbox members' do
        params = { inbox_id: inbox.id, user_ids: [agent_to_add.id] }

        patch "/api/v1/accounts/#{account.id}/inbox_members",
              headers: administrator.create_new_auth_token,
              params: params,
              as: :json

        expect(response).to have_http_status(:success)
        expect(inbox.inbox_members&.count).to eq(1)
        expect(inbox.inbox_members&.first&.user).to eq(agent_to_add)
      end

      it 'renders not found when inbox not found' do
        params = { inbox_id: nil, user_ids: [agent_to_add.id] }

        patch "/api/v1/accounts/#{account.id}/inbox_members",
              headers: administrator.create_new_auth_token,
              params: params,
              as: :json

        expect(response).to have_http_status(:not_found)
      end

      it 'renders error on invalid params' do
        params = { inbox_id: inbox.id, user_ids: ['invalid'] }

        patch "/api/v1/accounts/#{account.id}/inbox_members",
              headers: administrator.create_new_auth_token,
              params: params,
              as: :json

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.body).to include('User must exist')
      end
    end
  end

  describe 'DELETE /api/v1/accounts/{account.id}/inbox_members' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        delete "/api/v1/accounts/#{account.id}/inbox_members"

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

        delete "/api/v1/accounts/#{account.id}/inbox_members",
               headers: agent.create_new_auth_token,
               params: params,
               as: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an administrator' do
      let(:administrator) { create(:user, account: account, role: :administrator) }
      let(:old_agent) { create(:user, account: account, role: :agent) }
      let(:agent_to_delete) { create(:user, account: account, role: :agent) }
      let(:non_member_agent) { create(:user, account: account, role: :agent) }

      before do
        create(:inbox_member, user: old_agent, inbox: inbox)
        create(:inbox_member, user: agent_to_delete, inbox: inbox)
      end

      it 'deletes inbox members' do
        params = { inbox_id: inbox.id, user_ids: [agent_to_delete.id] }

        delete "/api/v1/accounts/#{account.id}/inbox_members",
               headers: administrator.create_new_auth_token,
               params: params,
               as: :json

        expect(response).to have_http_status(:success)
        expect(inbox.inbox_members&.count).to eq(1)
      end

      it 'renders not found when inbox not found' do
        params = { inbox_id: nil, user_ids: [agent_to_delete.id] }

        delete "/api/v1/accounts/#{account.id}/inbox_members",
               headers: administrator.create_new_auth_token,
               params: params,
               as: :json

        expect(response).to have_http_status(:not_found)
      end

      it 'ignores invalid params' do
        params = { inbox_id: inbox.id, user_ids: ['invalid'] }
        original_count = inbox.inbox_members&.count

        delete "/api/v1/accounts/#{account.id}/inbox_members",
               headers: administrator.create_new_auth_token,
               params: params,
               as: :json

        expect(response).to have_http_status(:success)
        expect(inbox.inbox_members&.count).to eq(original_count)
      end

      it 'ignores non member params' do
        params = { inbox_id: inbox.id, user_ids: [non_member_agent.id] }
        original_count = inbox.inbox_members&.count

        delete "/api/v1/accounts/#{account.id}/inbox_members",
               headers: administrator.create_new_auth_token,
               params: params,
               as: :json

        expect(response).to have_http_status(:success)
        expect(inbox.inbox_members&.count).to eq(original_count)
      end
    end
  end
end
