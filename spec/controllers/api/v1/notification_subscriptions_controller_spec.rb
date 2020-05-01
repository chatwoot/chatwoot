require 'rails_helper'

RSpec.describe 'Notifications Subscriptions API', type: :request do
  let(:account) { create(:account) }

  describe 'POST /api/v1/notification_subscriptions' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        post '/api/v1/notification_subscriptions'

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      let(:agent) { create(:user, account: account, role: :agent) }

      it 'creates a notification subscriptions' do
        post '/api/v1/notification_subscriptions',
             params: { notification_subscription: { subscription_type: 'browser_push', 'subscription_attributes': { test: 'test' } } },
             headers: agent.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:success)
        json_response = JSON.parse(response.body)
        expect(json_response['subscription_type']).to eq('browser_push')
        expect(json_response['subscription_attributes']).to eq({ 'test' => 'test' })
      end
    end
  end
end
