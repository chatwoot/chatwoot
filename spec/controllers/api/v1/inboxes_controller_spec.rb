require 'rails_helper'

RSpec.describe 'Inboxes API', type: :request do
  let(:account) { create(:account) }

  describe 'GET /api/v1/inboxes' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get '/api/v1/inboxes'

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      let(:agent) { create(:user, account: account, role: :agent) }
      let(:admin) { create(:user, account: account, role: :administrator) }

      before do
        create(:inbox, account: account)
        second_inbox = create(:inbox, account: account)
        create(:inbox_member, user: agent, inbox: second_inbox)
      end

      it 'returns all inboxes of current_account as administrator' do
        get '/api/v1/inboxes',
            headers: admin.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        expect(JSON.parse(response.body, symbolize_names: true)[:payload].size).to eq(2)
      end

      it 'returns only assigned inboxes of current_account as agent' do
        get '/api/v1/inboxes',
            headers: agent.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        expect(JSON.parse(response.body, symbolize_names: true)[:payload].size).to eq(1)
      end
    end
  end

  describe 'DELETE /api/v1/inboxes/:id' do
    let(:inbox) { create(:inbox, account: account) }

    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        delete "/api/v1/inboxes/#{inbox.id}"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      let(:admin) { create(:user, account: account, role: :administrator) }

      it 'deletes inbox' do
        delete "/api/v1/inboxes/#{inbox.id}",
               headers: admin.create_new_auth_token,
               as: :json

        expect(response).to have_http_status(:success)
        expect(Inbox.count).to eq(0)
      end

      it 'is unable to delete inbox of another account' do
        other_account = create(:account)
        other_inbox = create(:inbox, account: other_account)

        delete "/api/v1/inboxes/#{other_inbox.id}",
               headers: admin.create_new_auth_token,
               as: :json

        expect(response).to have_http_status(:not_found)
      end

      it 'is unable to delete inbox as agent' do
        agent = create(:user, account: account, role: :agent)

        delete "/api/v1/inboxes/#{inbox.id}",
               headers: agent.create_new_auth_token,
               as: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end
