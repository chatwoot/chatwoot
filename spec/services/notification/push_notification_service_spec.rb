require 'rails_helper'

describe Notification::PushNotificationService do
  let!(:account) { create(:account) }
  let!(:user) { create(:user, account: account) }
  let!(:notification) { create(:notification, user: user, account: user.accounts.first) }
  let(:fcm_double) { instance_double(FCM) }
  let(:fcm_service_double) { instance_double(Notification::FcmService, fcm_client: fcm_double) }

  describe '#perform' do
    context 'when the push server returns success' do
      before do
        allow(WebPush).to receive(:payload_send).and_return(true)
        allow(Rails.logger).to receive(:info)
        allow(Notification::FcmService).to receive(:new).and_return(fcm_service_double)
        allow(fcm_double).to receive(:send_v1).and_return(
          { status_code: 200, body: { name: 'projects/test/messages/1' }.to_json }
        )
        allow(GlobalConfigService).to receive(:load).with('FIREBASE_PROJECT_ID', nil).and_return('test_project_id')
        allow(GlobalConfigService).to receive(:load).with('FIREBASE_CREDENTIALS', nil).and_return('test_credentials')
      end

      it 'sends webpush notifications for webpush subscription' do
        with_modified_env VAPID_PUBLIC_KEY: 'test' do
          create(:notification_subscription, user: notification.user)

          described_class.new(notification: notification).perform
          expect(WebPush).to have_received(:payload_send)
          expect(Notification::FcmService).not_to have_received(:new)
          expect(Rails.logger).to have_received(:info).with("Browser push sent to #{user.email} with title #{notification.push_message_title}")
        end
      end

      it 'sends a fcm notification for firebase subscription' do
        with_modified_env ENABLE_PUSH_RELAY_SERVER: 'false' do
          create(:notification_subscription, user: notification.user, subscription_type: 'fcm')

          described_class.new(notification: notification).perform
          expect(Notification::FcmService).to have_received(:new)
          expect(fcm_double).to have_received(:send_v1)
          expect(WebPush).not_to have_received(:payload_send)
          expect(Rails.logger).to have_received(:info).with("FCM push sent to #{user.email} with title #{notification.push_message_title}")
        end
      end
    end
  end

  context 'when the push server returns error' do
    context 'with an FCM v1 error response' do
      let!(:subscription) { create(:notification_subscription, user: notification.user, subscription_type: 'fcm') }
      let(:error_code) { 'UNREGISTERED' }
      let(:response) do
        {
          status_code: 404,
          body: { error: { status: 'NOT_FOUND', details: [
            { '@type': 'type.googleapis.com/google.firebase.fcm.v1.FcmError', errorCode: error_code }
          ] } }.to_json
        }
      end

      before do
        allow(Notification::FcmService).to receive(:new).and_return(fcm_service_double)
        allow(fcm_double).to receive(:send_v1).and_return(response)
        allow(GlobalConfigService).to receive(:load).with('FIREBASE_PROJECT_ID', nil).and_return('test_project_id')
        allow(GlobalConfigService).to receive(:load).with('FIREBASE_CREDENTIALS', nil).and_return('test_credentials')
        allow(Rails.logger).to receive(:info)
        allow(Rails.logger).to receive(:warn)
      end

      it 'removes an unregistered token and reports the failure' do
        described_class.new(notification: notification).perform

        expect(NotificationSubscription.exists?(subscription.id)).to be(false)
        expect(Rails.logger).to have_received(:warn).with("FCM push failed for subscription #{subscription.id}: HTTP 404 (UNREGISTERED)")
        expect(Rails.logger).not_to have_received(:info).with(/FCM push sent/)
      end

      %w[INVALID_ARGUMENT SENDER_ID_MISMATCH THIRD_PARTY_AUTH_ERROR QUOTA_EXCEEDED UNAVAILABLE INTERNAL].each do |code|
        context "with #{code}" do
          let(:error_code) { code }

          it 'keeps the subscription and reports the failure' do
            described_class.new(notification: notification).perform

            expect(NotificationSubscription.exists?(subscription.id)).to be(true)
            expect(Rails.logger).to have_received(:warn).with(/#{code}/)
            expect(Rails.logger).not_to have_received(:info).with(/FCM push sent/)
          end
        end
      end

      context 'when the error carries no FCM details' do
        let(:response) { { status_code: 401, body: { error: { status: 'UNAUTHENTICATED' } }.to_json } }

        it 'keeps the subscription and reports the API status' do
          described_class.new(notification: notification).perform

          expect(NotificationSubscription.exists?(subscription.id)).to be(true)
          expect(Rails.logger).to have_received(:warn).with(/HTTP 401 \(UNAUTHENTICATED\)/)
        end
      end

      context 'when the body is not JSON' do
        let(:response) { { status_code: 503, body: '<html>Service unavailable</html>' } }

        it 'keeps the subscription and reports the HTTP failure' do
          described_class.new(notification: notification).perform

          expect(NotificationSubscription.exists?(subscription.id)).to be(true)
          expect(Rails.logger).to have_received(:warn).with(/HTTP 503 \(UNKNOWN\)/)
        end
      end
    end

    it 'sends webpush notifications for webpush subscription' do
      with_modified_env VAPID_PUBLIC_KEY: 'test' do
        mock_response = instance_double(Net::HTTPResponse, body: 'Subscription is invalid')
        mock_host = 'fcm.googleapis.com'

        allow(WebPush).to receive(:payload_send).and_raise(WebPush::InvalidSubscription.new(mock_response, mock_host))
        allow(Rails.logger).to receive(:info)

        create(:notification_subscription, :browser_push, user: notification.user)

        expect(Rails.logger).to receive(:info) do |message|
          expect(message).to include('WebPush subscription expired:')
        end

        described_class.new(notification: notification).perform
      end
    end
  end
end
