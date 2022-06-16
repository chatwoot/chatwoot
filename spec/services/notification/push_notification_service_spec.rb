require 'rails_helper'

describe Notification::PushNotificationService do
  let!(:account) { create(:account) }
  let!(:user) { create(:user, account: account) }
  let!(:notification) { create(:notification, user: user, account: user.accounts.first) }
  let(:fcm_double) { double }

  before do
    allow(Webpush).to receive(:payload_send).and_return(true)
    allow(FCM).to receive(:new).and_return(fcm_double)
    allow(fcm_double).to receive(:send).and_return({ body: { 'results': [] }.to_json })
  end

  describe '#perform' do
    it 'sends webpush notifications for webpush subscription' do
      with_modified_env VAPID_PUBLIC_KEY: 'test' do
        create(:notification_subscription, user: notification.user)

        described_class.new(notification: notification).perform
        expect(Webpush).to have_received(:payload_send)
        expect(FCM).not_to have_received(:new)
      end
    end

    it 'sends a fcm notification for firebase subscription' do
      with_modified_env FCM_SERVER_KEY: 'test', ENABLE_PUSH_RELAY_SERVER: 'false' do
        create(:notification_subscription, user: notification.user, subscription_type: 'fcm')

        described_class.new(notification: notification).perform
        expect(FCM).to have_received(:new)
        expect(Webpush).not_to have_received(:payload_send)
      end
    end
  end
end
