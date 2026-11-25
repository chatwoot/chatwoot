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

  describe '#perform push target' do
    let(:pushed_payloads) { [] }

    before do
      user.notification_settings.find_by(account_id: account.id)
          .update!(selected_push_flags: [:push_conversation_assignment, :push_internal_chat_mention])
      allow(WebPush).to receive(:payload_send) { |**payload| pushed_payloads << payload }
      allow(Rails.logger).to receive(:info)
      create(:notification_subscription, :browser_push, user: user)
    end

    context 'when the notification comes from internal chat' do
      let(:channel) { create(:internal_chat_channel, account: account) }
      let(:message) { create(:internal_chat_message, account: account, channel: channel, sender: create(:user, account: account)) }
      let(:internal_chat_notification) do
        create(:notification, user: user, account: account, primary_actor: channel, secondary_actor: message,
                              notification_type: 'internal_chat_mention')
      end

      it 'points the push at the channel instead of raising on display_id' do
        with_modified_env VAPID_PUBLIC_KEY: 'test', FRONTEND_URL: 'https://app.example.com' do
          described_class.new(notification: internal_chat_notification).perform

          expect(JSON.parse(pushed_payloads.first[:message])).to include(
            'url' => "https://app.example.com/app/accounts/#{account.id}/internal-chat/channels/#{channel.id}",
            'tag' => "internal_chat_mention_#{channel.id}_#{internal_chat_notification.id}"
          )
        end
      end

      context 'when the channel is a direct message' do
        let(:channel) { create(:internal_chat_channel, :dm, account: account) }

        it 'points the push at the dm route' do
          with_modified_env VAPID_PUBLIC_KEY: 'test', FRONTEND_URL: 'https://app.example.com' do
            described_class.new(notification: internal_chat_notification).perform

            expect(JSON.parse(pushed_payloads.first[:message])['url'])
              .to eq("https://app.example.com/app/accounts/#{account.id}/internal-chat/dm/#{channel.id}")
          end
        end
      end
    end

    context 'when the notification comes from a conversation' do
      let(:conversation) { create(:conversation, account: account) }
      let(:conversation_notification) do
        create(:notification, user: user, account: account, primary_actor: conversation, notification_type: 'conversation_assignment')
      end

      # The host comes from the route helper's default_url_options, not from the env at call time.
      it 'keeps addressing the conversation by display_id' do
        with_modified_env VAPID_PUBLIC_KEY: 'test' do
          described_class.new(notification: conversation_notification).perform

          pushed = JSON.parse(pushed_payloads.first[:message])
          expect(pushed['url']).to end_with("/app/accounts/#{account.id}/conversations/#{conversation.display_id}")
          expect(pushed['tag']).to eq("conversation_assignment_#{conversation.display_id}_#{conversation_notification.id}")
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
