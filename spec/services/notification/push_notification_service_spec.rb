require 'rails_helper'

describe Notification::PushNotificationService do
  let!(:account) { create(:account) }
  let!(:user) { create(:user, account: account) }
  let!(:notification) { create(:notification, user: user, account: user.accounts.first) }
  let(:fcm_double) { instance_double(FCM) }
  let(:fcm_service_double) { instance_double(Notification::FcmService, fcm_client: fcm_double) }

  before do
    allow(WebPush).to receive(:payload_send).and_return(true)
    allow(Notification::FcmService).to receive(:new).and_return(fcm_service_double)
    allow(fcm_double).to receive(:send_v1).and_return({ body: { 'results': [] }.to_json })
    allow(GlobalConfigService).to receive(:load).with('FIREBASE_PROJECT_ID', nil).and_return('test_project_id')
    allow(GlobalConfigService).to receive(:load).with('FIREBASE_CREDENTIALS', nil).and_return('test_credentials')
  end

  describe '#perform' do
    it 'sends webpush notifications for webpush subscription' do
      with_modified_env VAPID_PUBLIC_KEY: 'test' do
        create(:notification_subscription, user: notification.user)

        described_class.new(notification: notification).perform
        expect(WebPush).to have_received(:payload_send)
        expect(Notification::FcmService).not_to have_received(:new)
      end
    end

    it 'sends a fcm notification for firebase subscription' do
      with_modified_env ENABLE_PUSH_RELAY_SERVER: 'false' do
        create(:notification_subscription, user: notification.user, subscription_type: 'fcm')

        described_class.new(notification: notification).perform
        expect(Notification::FcmService).to have_received(:new)
        expect(fcm_double).to have_received(:send_v1)
        expect(WebPush).not_to have_received(:payload_send)
      end
    end
  end
end
