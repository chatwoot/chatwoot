# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Voice::VoipPushService do
  let(:account) { create(:account) }
  let(:channel) { create(:channel_twilio_sms, :with_voice, account: account, phone_number: '+15551239999') }
  let(:inbox) { channel.inbox }
  let(:agent) { create(:user, account: account, role: :agent) }
  let(:other_agent) { create(:user, account: account, role: :agent) }
  let(:contact) { create(:contact, account: account, name: 'Priya', phone_number: '+919999999999') }
  let(:conversation) { create(:conversation, account: account, inbox: inbox, contact: contact, assignee: nil) }
  let(:call) { create(:call, conversation: conversation) }

  let(:config) do
    {
      'APNS_VOIP_KEY' => 'p8-contents', 'APNS_VOIP_KEY_ID' => 'KEY1', 'APNS_VOIP_TEAM_ID' => 'TEAM1',
      'FIREBASE_PROJECT_ID' => 'project', 'FIREBASE_CREDENTIALS' => '{}'
    }
  end
  let(:apple_response) { instance_double(Apnotic::Response, status: '200', body: '') }
  let(:apple_connection) { instance_double(Apnotic::Connection, push: apple_response, close: nil) }
  let(:fcm_client) { instance_double(FCM, send_v1: { status_code: 200, body: '' }) }

  before do
    allow(Twilio::VoiceWebhookSetupService).to receive(:new)
      .and_return(instance_double(Twilio::VoiceWebhookSetupService, perform: "AP#{SecureRandom.hex(8)}"))
    allow(GlobalConfigService).to receive(:load) { |key, default| config.fetch(key, default) }
    allow(Apnotic::Connection).to receive(:new).and_return(apple_connection)
    allow(Notification::FcmService).to receive(:new).and_return(instance_double(Notification::FcmService, fcm_client: fcm_client))
    create(:inbox_member, inbox: inbox, user: agent)
    create(:inbox_member, inbox: inbox, user: other_agent)
  end

  def subscribe(user, type, token, platform: nil)
    attributes = { push_token: token, device_id: "device-#{token}" }
    attributes[:devicePlatform] = platform if platform
    create(:notification_subscription, user: user, subscription_type: type, identifier: "#{type}:#{token}",
                                       subscription_attributes: attributes)
  end

  describe 'ring' do
    it 'sends a VoIP push to each iPhone of the eligible agents' do
      subscribe(agent, 'apns_voip', 'apple-1')
      subscribe(other_agent, 'fcm', 'ios-fcm', platform: 'iOS')

      described_class.new(call: call).perform('ring')

      expect(apple_connection).to have_received(:push).once do |notification|
        expect(notification.push_type).to eq('voip')
        expect(notification.topic).to eq('com.chatwoot.app.voip')
        expect(notification.custom_payload).to include(type: 'voice_call.incoming', id: call.id, provider: 'twilio')
        expect(notification.custom_payload[:caller]).to eq(name: 'Priya', phone: '+919999999999', avatar: nil)
      end
      expect(fcm_client).not_to have_received(:send_v1)
    end

    it 'sends a high-priority data message to each Android phone of the eligible agents' do
      subscribe(agent, 'fcm', 'android-1', platform: 'Android')
      subscribe(other_agent, 'fcm', 'ios-fcm', platform: 'iOS')

      described_class.new(call: call).perform('ring')

      expect(fcm_client).to have_received(:send_v1).once.with(
        hash_including(token: 'android-1', android: { priority: 'high', ttl: '45s' })
      ) do |args|
        expect(args[:data]).to include('type' => 'voice_call.incoming', 'id' => call.id.to_s, 'inbox_name' => inbox.name)
        expect(JSON.parse(args[:data]['caller'])).to include('name' => 'Priya')
      end
    end

    it 'rings only the assignee when the conversation is assigned' do
      conversation.update!(assignee: agent)
      subscribe(agent, 'apns_voip', 'apple-assignee')
      subscribe(other_agent, 'apns_voip', 'apple-other')

      described_class.new(call: call).perform('ring')

      expect(apple_connection).to have_received(:push).once do |notification|
        expect(notification.token).to eq('apple-assignee')
      end
    end

    it 'remembers which devices were rung on the call' do
      subscribe(agent, 'apns_voip', 'apple-1')
      subscribe(agent, 'fcm', 'android-1', platform: 'Android')

      described_class.new(call: call).perform('ring')

      expect(call.reload.meta['rung_devices']).to eq('apns_voip' => ['apple-1'], 'fcm' => ['android-1'])
    end

    it 'removes devices the platforms no longer know' do
      subscribe(agent, 'apns_voip', 'apple-gone')
      subscribe(agent, 'fcm', 'android-gone', platform: 'Android')
      allow(apple_response).to receive(:status).and_return('410')
      allow(fcm_client).to receive(:send_v1).and_return(status_code: 404, body: '{"error":{"details":[{"errorCode":"UNREGISTERED"}]}}')

      expect { described_class.new(call: call).perform('ring') }.to change(NotificationSubscription, :count).by(-2)
    end

    it 'does nothing without any registered phone' do
      described_class.new(call: call).perform('ring')

      expect(apple_connection).not_to have_received(:push)
      expect(fcm_client).not_to have_received(:send_v1)
      expect(call.reload.meta['rung_devices']).to be_nil
    end

    it 'skips Apple when the APNs key is not configured' do
      config.delete('APNS_VOIP_KEY')
      subscribe(agent, 'apns_voip', 'apple-1')
      subscribe(agent, 'fcm', 'android-1', platform: 'Android')

      described_class.new(call: call).perform('ring')

      expect(Apnotic::Connection).not_to have_received(:new)
      expect(fcm_client).to have_received(:send_v1).once
    end

    it 'keeps going for the other devices when one delivery raises' do
      subscribe(agent, 'apns_voip', 'apple-1')
      subscribe(agent, 'fcm', 'android-1', platform: 'Android')
      allow(apple_connection).to receive(:push).and_raise(SocketError)

      expect { described_class.new(call: call).perform('ring') }.not_to raise_error
      expect(fcm_client).to have_received(:send_v1).once
    end
  end

  describe 'cancel' do
    before do
      call.update!(status: 'no_answer', meta: { 'rung_devices' => { 'apns_voip' => ['apple-1'], 'fcm' => %w[android-1 android-2] } })
    end

    it 'sends a cancel data message to the Android phones that were rung, and nothing to Apple' do
      described_class.new(call: call).perform('cancel')

      expect(Apnotic::Connection).not_to have_received(:new)
      expect(fcm_client).to have_received(:send_v1).twice do |args|
        expect(args[:data]).to include('type' => 'voice_call.cancel', 'reason' => 'no_answer', 'id' => call.id.to_s)
      end
    end

    it 'does nothing for an outbound call' do
      call.update!(direction: :outgoing)

      described_class.new(call: call).perform('cancel')

      expect(fcm_client).not_to have_received(:send_v1)
    end

    it 'does nothing when no Android phone was rung' do
      call.update!(meta: { 'rung_devices' => { 'apns_voip' => ['apple-1'], 'fcm' => [] } })

      described_class.new(call: call).perform('cancel')

      expect(fcm_client).not_to have_received(:send_v1)
    end
  end
end
