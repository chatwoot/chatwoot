require 'rails_helper'

RSpec.describe 'Api::V1::Accounts::Insights', type: :request do
  let(:account) { create(:account) }
  let(:user) { create(:user, account: account, role: :administrator) }
  let!(:insight) { create(:insight, account: account, user: user) }

  describe 'GET /api/v1/accounts/{account.id}/insights' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get "/api/v1/accounts/#{account.id}/insights"
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      it 'returns all insights' do
        get "/api/v1/accounts/#{account.id}/insights",
            headers: user.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        expect(JSON.parse(response.body).size).to eq(1)
        expect(JSON.parse(response.body).first['id']).to eq(insight.id)
      end
    end
  end
end
