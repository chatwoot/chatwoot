require 'rails_helper'

RSpec.describe 'Subscriptions API', type: :request do
  let(:account) { create(:account) }

  describe 'GET /api/v1/accounts/{account.id}/subscriptions' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        ENV['BILLING_ENABLED'] = 'true'

        get "/api/v1/accounts/#{account.id}/subscriptions"

        expect(response).to have_http_status(:unauthorized)

        ENV['BILLING_ENABLED'] = nil
      end
    end

    context 'when it is an authenticated user' do
      let(:agent) { create(:user, account: account, role: :agent) }

      it 'returns all subscriptions' do
        ENV['BILLING_ENABLED'] = 'true'

        get "/api/v1/accounts/#{account.id}/subscriptions",
            headers: agent.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        expect(JSON.parse(response.body)).to eq(account.subscription_data.as_json)

        ENV['BILLING_ENABLED'] = nil
      end

      it 'throws 404 error if env variable is not set' do
        ENV['BILLING_ENABLED'] = nil

        get "/api/v1/accounts/#{account.id}/subscriptions",
            headers: agent.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
