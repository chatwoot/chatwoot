require 'rails_helper'

RSpec.describe 'Label API', type: :request do
  let(:account) { create(:account) }
  let(:conversation) { create(:conversation, account: account) }

  before do
    conversation.update_labels('label1, label2')
  end

  describe 'GET /api/v1/labels' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get '/api/v1/labels'

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      let(:agent) { create(:user, account: account, role: :agent) }

      it 'returns all the labels in account' do
        get '/api/v1/labels',
            headers: agent.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        expect(response.body).to include('label1')
        expect(response.body).to include('label2')
      end
    end
  end
end
