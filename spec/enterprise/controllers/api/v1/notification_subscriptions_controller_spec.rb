require 'rails_helper'

RSpec.describe 'Notifications Subscriptions API for VoIP tokens', type: :request do
  let(:account) { create(:account) }
  let(:agent) { create(:user, account: account, role: :agent) }

  describe 'POST /api/v1/notification_subscriptions' do
    it 'registers a VoIP push token as its own subscription' do
      post '/api/v1/notification_subscriptions',
           params: {
             notification_subscription: {
               subscription_type: 'apns_voip',
               'subscription_attributes': {
                 push_token: 'voip-token',
                 device_id: 'phone-1',
                 devicePlatform: 'iOS'
               }
             }
           },
           headers: agent.create_new_auth_token,
           as: :json

      expect(response).to have_http_status(:success)
      json_response = response.parsed_body
      expect(json_response['subscription_type']).to eq('apns_voip')
      expect(json_response['identifier']).to eq('voip:phone-1')
    end

    it 'rejects a VoIP push token that names no device' do
      post '/api/v1/notification_subscriptions',
           params: {
             notification_subscription: {
               subscription_type: 'apns_voip',
               'subscription_attributes': { push_token: 'voip-token', devicePlatform: 'iOS' }
             }
           },
           headers: agent.create_new_auth_token,
           as: :json

      expect(response).to have_http_status(:unprocessable_entity)
      expect(NotificationSubscription.apns_voip.count).to eq(0)
    end

    it 'rejects a VoIP registration whose device id is not a string' do
      post '/api/v1/notification_subscriptions',
           params: {
             notification_subscription: {
               subscription_type: 'apns_voip',
               'subscription_attributes': { push_token: 'voip-token', device_id: 12_345, devicePlatform: 'iOS' }
             }
           },
           headers: agent.create_new_auth_token,
           as: :json

      expect(response).to have_http_status(:unprocessable_entity)
      expect(NotificationSubscription.apns_voip.count).to eq(0)
    end

    it 'rejects a VoIP registration without a push token, leaving the device its existing one' do
      existing = create(:notification_subscription, user: agent, subscription_type: 'apns_voip', identifier: 'voip:phone-1',
                                                    subscription_attributes: { push_token: 'voip-token', device_id: 'phone-1' })

      post '/api/v1/notification_subscriptions',
           params: {
             notification_subscription: {
               subscription_type: 'apns_voip',
               'subscription_attributes': { device_id: 'phone-1', devicePlatform: 'iOS' }
             }
           },
           headers: agent.create_new_auth_token,
           as: :json

      expect(response).to have_http_status(:unprocessable_entity)
      expect(existing.reload.subscription_attributes['push_token']).to eq('voip-token')
    end
  end

  describe 'DELETE /api/v1/notification_subscriptions' do
    it 'deletes the VoIP row of the same phone when its FCM token is removed, and only that phone' do
      fcm = create(:notification_subscription, user: agent, subscription_type: 'fcm', identifier: 'phone-1',
                                               subscription_attributes: { push_token: 'fcm-1', device_id: 'phone-1' })
      voip = create(:notification_subscription, user: agent, subscription_type: 'apns_voip', identifier: 'voip:phone-1',
                                                subscription_attributes: { push_token: 'voip-1', device_id: 'phone-1' })
      other_phone = create(:notification_subscription, user: agent, subscription_type: 'apns_voip', identifier: 'voip:phone-2',
                                                       subscription_attributes: { push_token: 'voip-2', device_id: 'phone-2' })

      delete '/api/v1/notification_subscriptions',
             params: { push_token: 'fcm-1' },
             headers: agent.create_new_auth_token,
             as: :json

      expect(response).to have_http_status(:success)
      expect(NotificationSubscription.where(id: [fcm.id, voip.id])).to be_empty
      expect { other_phone.reload }.not_to raise_error
    end
  end
end
