require 'rails_helper'

RSpec.describe 'Subscriptions API', type: :request do
  let(:account) { create(:account) }

  describe 'GET /api/v1/subscriptions' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get '/api/v1/subscriptions'

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      let(:agent) { create(:user, account: account, role: :agent) }

      it 'returns all subscriptions' do
        get '/api/v1/subscriptions',
            headers: agent.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        expect(JSON.parse(response.body)).to eq(account.subscription_data.as_json)
      end
    end
  end
end
