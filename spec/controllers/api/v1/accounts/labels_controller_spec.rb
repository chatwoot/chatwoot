require 'rails_helper'

RSpec.describe 'Label API', type: :request do
  let(:account) { create(:account) }
  let(:conversation) { create(:conversation, account: account) }

  before do
    conversation.update_labels('label1, label2')
  end

  describe 'GET /api/v1/accounts/{account.id}/labels' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get "/api/v1/accounts/#{account.id}/labels"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      let(:agent) { create(:user, account: account, role: :agent) }

      it 'returns all the labels in account' do
        get "/api/v1/accounts/#{account.id}/labels",
            headers: agent.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        expect(response.body).to include('label1')
        expect(response.body).to include('label2')
      end
    end
  end

  describe 'GET /api/v1/accounts/{account.id}/labels/most_used' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get "/api/v1/accounts/#{account.id}/labels"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      let(:agent) { create(:user, account: account, role: :agent) }

      it 'returns most used labels' do
        get "/api/v1/accounts/#{account.id}/labels/most_used",
            headers: agent.create_new_auth_token,
            params: { count: 1 },
            as: :json

        expect(response).to have_http_status(:success)
        expect(response.body).to include('label1')
        expect(response.body).not_to include('label2')
      end
    end
  end
end
