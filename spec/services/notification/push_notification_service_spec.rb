require 'rails_helper'

describe Notification::PushNotificationService do
  let(:account) { create(:account) }
  let(:user) { create(:user, account: account) }
  let(:notification) { create(:notification, user: user, account: user.accounts.first) }
  let(:fcm_double) { instance_double(FCM) }
  let(:fcm_service_double) { instance_double(Notification::FcmService, fcm_client: fcm_double) }

  before do
    allow(InstallationConfig).to receive(:find_by).and_call_original
    allow(InstallationConfig).to receive(:find_by)
      .with(name: 'ACCOUNT_LEVEL_FEATURE_DEFAULTS')
      .and_return(nil)
    allow(InstallationConfig).to receive(:find_by)
      .with(name: 'INSTALLATION_PRICING_PLAN')
      .and_return(nil)
  end

  describe '#perform' do
    context 'when the push server returns success' do
      before do
        allow(WebPush).to receive(:payload_send).and_return(true)
        allow(Rails.logger).to receive(:info)
        allow(Notification::FcmService).to receive(:new).and_return(fcm_service_double)
        allow(fcm_double).to receive(:send_v1).and_return({ body: { 'results': [] }.to_json })
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

      it 'embeds conversation, sender and reply context in the webpush payload' do
        with_modified_env VAPID_PUBLIC_KEY: 'test' do
          create(:notification_subscription, user: notification.user)

          described_class.new(notification: notification).perform

          captured = nil
          expect(WebPush).to have_received(:payload_send) do |args|
            captured = JSON.parse(args[:message])
          end

          expect(captured).to include(
            'title' => notification.push_message_title,
            'account_id' => notification.account.id,
            'conversation_id' => notification.conversation.display_id,
            'conversation_uuid' => notification.conversation.uuid,
            'notification_id' => notification.id,
            'notification_type' => notification.notification_type
          )
          expect(captured['tag']).to eq("conversation_#{notification.account.id}_#{notification.conversation.display_id}")
          expect(captured).to have_key('reply_enabled')
          expect(captured['sender']).to be_a(Hash).or be_nil
          expect(captured['timestamp']).to be_a(Integer)
        end
      end

      it 'flags reply_enabled true for new-message notifications on a repliable conversation' do
        with_modified_env VAPID_PUBLIC_KEY: 'test' do
          notification.update!(notification_type: 'assigned_conversation_new_message')
          allow(notification.conversation).to receive(:can_reply?).and_return(true)
          allow_any_instance_of(described_class).to receive(:conversation).and_return(notification.conversation)
          create(:notification_subscription, user: notification.user)

          described_class.new(notification: notification).perform

          captured = nil
          expect(WebPush).to have_received(:payload_send) do |args|
            captured = JSON.parse(args[:message])
          end
          expect(captured['reply_enabled']).to be true
        end
      end

      it 'flags reply_enabled false when the conversation cannot accept replies' do
        with_modified_env VAPID_PUBLIC_KEY: 'test' do
          notification.update!(notification_type: 'assigned_conversation_new_message')
          allow(notification.conversation).to receive(:can_reply?).and_return(false)
          allow_any_instance_of(described_class).to receive(:conversation).and_return(notification.conversation)
          create(:notification_subscription, user: notification.user)

          described_class.new(notification: notification).perform

          captured = nil
          expect(WebPush).to have_received(:payload_send) do |args|
            captured = JSON.parse(args[:message])
          end
          expect(captured['reply_enabled']).to be false
        end
      end

      it 'does not send standard push when infinitepay push only is enabled for the account' do
        with_modified_env VAPID_PUBLIC_KEY: 'test' do
          account.update!(custom_attributes: account.custom_attributes.merge('infinitepay_push_only' => true))
          create(:notification_subscription, user: notification.user)

          described_class.new(notification: notification).perform

          expect(WebPush).not_to have_received(:payload_send)
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
