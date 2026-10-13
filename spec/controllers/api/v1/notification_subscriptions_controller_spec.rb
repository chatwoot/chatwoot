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
             params: {
               notification_subscription: {
                 subscription_type: 'browser_push',
                 'subscription_attributes': {
                   endpoint: 'test',
                   p256dh: 'test',
                   auth: 'test'
                 }
               }
             },
             headers: agent.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:success)
        json_response = response.parsed_body
        expect(json_response['subscription_type']).to eq('browser_push')
        expect(json_response['subscription_attributes']['auth']).to eq('test')
      end

      it 'returns existing notification subscription if subscription exists' do
        subscription = create(:notification_subscription, user: agent)
        post '/api/v1/notification_subscriptions',
             params: {
               notification_subscription: {
                 subscription_type: 'browser_push',
                 'subscription_attributes': {
                   endpoint: 'test',
                   p256dh: 'test',
                   auth: 'test'
                 }
               }
             },
             headers: agent.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:success)
        json_response = response.parsed_body
        expect(json_response['id']).to eq(subscription.id)
      end

      it 'move notification subscription to user if its of another user' do
        subscription = create(:notification_subscription, user: create(:user))
        post '/api/v1/notification_subscriptions',
             params: {
               notification_subscription: {
                 subscription_type: 'browser_push',
                 'subscription_attributes': {
                   endpoint: 'test',
                   p256dh: 'test',
                   auth: 'test'
                 }
               }
             },
             headers: agent.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:success)
        json_response = response.parsed_body
        expect(json_response['id']).to eq(subscription.id)
        expect(json_response['user_id']).to eq(agent.id)
      end
    end
  end

  describe 'DELETE /api/v1/notification_subscriptions' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        delete '/api/v1/notification_subscriptions'

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated user' do
      let(:agent) { create(:user, account: account, role: :agent) }

      it 'delete existing notification subscription if subscription exists' do
        subscription = create(:notification_subscription, subscription_type: 'fcm', subscription_attributes: { push_token: 'bUvZo8AYGGmCMr' },
                                                          user: agent)
        delete '/api/v1/notification_subscriptions',
               params: {
                 push_token: subscription.subscription_attributes['push_token']
               },
               headers: agent.create_new_auth_token,
               as: :json

        expect(response).to have_http_status(:success)
        expect { subscription.reload }.to raise_exception(ActiveRecord::RecordNotFound)
      end

      it 'does not delete another user notification subscription with the same push token' do
        victim = create(:user, account: account, role: :agent)
        victim_subscription = create(:notification_subscription, subscription_type: 'fcm',
                                                                 subscription_attributes: { push_token: 'victimToken' },
                                                                 user: victim)

        delete '/api/v1/notification_subscriptions',
               params: { push_token: 'victimToken' },
               headers: agent.create_new_auth_token,
               as: :json

        expect(response).to have_http_status(:success)
        expect { victim_subscription.reload }.not_to raise_error
      end
    end
  end

  describe 'MFA enforcement over api_access_token' do
    let(:agent) { create(:user, account: account, role: :agent) }

    before do
      skip('Skipping since MFA is not configured in this environment') unless Chatwoot.encryption_configured?
      account.update!(enforce_mfa: true)
    end

    it 'blocks non-enrolled users from registering a push recipient' do
      post '/api/v1/notification_subscriptions',
           params: {
             notification_subscription: {
               subscription_type: 'fcm',
               subscription_attributes: { push_token: 'blocked-token', device_id: 'device-1' }
             }
           },
           headers: { api_access_token: agent.access_token.token },
           as: :json

      expect(response).to have_http_status(:forbidden)
      expect(response.parsed_body['error_code']).to eq('mfa_enrollment_required')
    end

    it 'allows enrolled users' do
      agent.enable_two_factor!
      agent.update!(otp_required_for_login: true)

      post '/api/v1/notification_subscriptions',
           params: {
             notification_subscription: {
               subscription_type: 'fcm',
               subscription_attributes: { push_token: 'enrolled-token', device_id: 'device-1' }
             }
           },
           headers: { api_access_token: agent.access_token.token },
           as: :json

      expect(response).to have_http_status(:success)
    end
  end
end
