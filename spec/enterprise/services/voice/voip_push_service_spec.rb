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
        expect(notification.custom_payload).to include(type: 'voice_call.incoming', id: call.id, provider: 'twilio',
                                                       conversation_id: call.conversation.display_id, account_id: call.account_id)
        expect(notification.custom_payload[:caller]).to eq(name: 'Priya', phone: '+919999999999', avatar: nil)
      end
      expect(fcm_client).not_to have_received(:send_v1)
    end

    it 'does not hold up later iPhones behind a slow response' do
      third_agent = create(:user, account: account, role: :agent)
      create(:inbox_member, inbox: inbox, user: third_agent)
      [[agent, 'apple-1'], [other_agent, 'apple-2'], [third_agent, 'apple-3']].each { |user, token| subscribe(user, 'apns_voip', token) }
      third_started = Queue.new
      events = []
      lock = Mutex.new
      allow(apple_connection).to receive(:push) do
        order = lock.synchronize do
          events << :start
          events.count(:start)
        end
        # The second push waits for the third, which only starts if they are sent together
        Timeout.timeout(2) { third_started.pop } if order == 2
        third_started << true if order == 3
        lock.synchronize { events << :"finish_#{order}" }
        apple_response
      end

      described_class.new(call: call).perform('ring')

      expect(events).to include(:finish_2)
      expect(events.count(:start)).to eq(3)
    end

    it 'rings iPhones while the Firebase client is still being set up' do
      subscribe(agent, 'apns_voip', 'apple-1')
      subscribe(other_agent, 'fcm', 'android-1', platform: 'Android')
      apple_pushed = Queue.new
      allow(apple_connection).to receive(:push) do
        apple_pushed << true
        apple_response
      end
      firebase = instance_double(Notification::FcmService)
      allow(firebase).to receive(:fcm_client) { Timeout.timeout(2) { apple_pushed.pop } && fcm_client }
      allow(Notification::FcmService).to receive(:new).and_return(firebase)

      described_class.new(call: call).perform('ring')

      expect(fcm_client).to have_received(:send_v1).with(hash_including(token: 'android-1'))
    end

    it 'does not count an agent whose only phone has no push token as reachable' do
      create(:notification_subscription, user: agent, subscription_type: 'fcm', identifier: 'fcm:no-token',
                                         subscription_attributes: { device_id: 'device-no-token', devicePlatform: 'Android' })

      expect(described_class.new(call: call).ringable_user_ids).to be_empty
    end

    it 'still rings iPhones when the Firebase client cannot be set up' do
      subscribe(agent, 'apns_voip', 'apple-1')
      subscribe(other_agent, 'fcm', 'android-1', platform: 'Android')
      allow(Notification::FcmService).to receive(:new).and_raise(IOError, 'token request failed')

      described_class.new(call: call).perform('ring')

      expect(apple_connection).to have_received(:push).once
      expect(call.reload.ring_state['unreached_user_ids']).to eq([other_agent.id])
    end

    it 'sends a high-priority data message to each Android phone of the eligible agents' do
      subscribe(agent, 'fcm', 'android-1', platform: 'Android')
      subscribe(other_agent, 'fcm', 'ios-fcm', platform: 'iOS')

      described_class.new(call: call).perform('ring')

      expect(fcm_client).to have_received(:send_v1).once.with(
        hash_including(token: 'android-1', android: { priority: 'high', ttl: '45s' })
      ) do |args|
        expect(args[:data]).to include('type' => 'voice_call.incoming', 'id' => call.id.to_s, 'inbox_name' => inbox.name,
                                       'conversation_id' => call.conversation.display_id.to_s)
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

      expect(call.reload.ring_state['rung_devices']).to eq('apns_voip' => ['apple-1'], 'fcm' => ['android-1'])
    end

    it 'removes devices the platforms no longer know' do
      subscribe(agent, 'apns_voip', 'apple-gone')
      subscribe(agent, 'fcm', 'android-gone', platform: 'Android')
      allow(apple_response).to receive(:status).and_return('410')
      allow(fcm_client).to receive(:send_v1).and_return(status_code: 404, body: '{"error":{"details":[{"errorCode":"UNREGISTERED"}]}}')

      expect { described_class.new(call: call).perform('ring') }.to change(NotificationSubscription, :count).by(-2)
    end

    it 'sends the new-message notification to agents the ring turned out not to reach' do
      message = create(:message, message_type: :incoming, content_type: :voice_call, account: account, conversation: conversation)
      call.update!(message: message)
      subscribe(agent, 'apns_voip', 'apple-gone')
      allow(apple_response).to receive(:status).and_return('410')
      service = instance_double(Messages::NewMessageNotificationService, perform: nil)
      allow(Messages::NewMessageNotificationService).to receive(:new).with(message: message).and_return(service)

      described_class.new(call: call).perform('ring')

      expect(service).to have_received(:perform)
    end

    it 'treats an agent whose every push failed as not rung' do
      message = create(:message, message_type: :incoming, content_type: :voice_call, account: account, conversation: conversation)
      call.update!(message: message)
      subscribe(agent, 'apns_voip', 'apple-down')
      subscribe(other_agent, 'apns_voip', 'apple-up')
      allow(apple_connection).to receive(:push) do |notification|
        raise Errno::ECONNRESET if notification.token == 'apple-down'

        apple_response
      end
      service = instance_double(Messages::NewMessageNotificationService, perform: nil)
      allow(Messages::NewMessageNotificationService).to receive(:new).with(message: message).and_return(service)

      described_class.new(call: call).perform('ring')

      expect(call.reload.ring_state['unreached_user_ids']).to eq([agent.id])
      expect(described_class.new(call: call).ringable_user_ids).to eq([other_agent.id])
      expect(service).to have_received(:perform)
      expect(NotificationSubscription.where(user: agent)).to exist
    end

    it 'treats a push the platform rejected as not reaching the agent' do
      subscribe(agent, 'apns_voip', 'apple-1')
      allow(apple_response).to receive(:status).and_return('500')

      described_class.new(call: call).perform('ring')

      expect(call.reload.ring_state['unreached_user_ids']).to eq([agent.id])
    end

    it 'knows whose device failed even when its subscription goes away during the ring' do
      subscribe(agent, 'apns_voip', 'apple-1')
      allow(apple_connection).to receive(:push) do
        NotificationSubscription.where(user: agent).destroy_all
        raise Errno::ECONNRESET
      end

      described_class.new(call: call).perform('ring')

      expect(call.reload.ring_state['unreached_user_ids']).to eq([agent.id])
    end

    it 'treats every device as not reached when the connection cannot be made' do
      subscribe(agent, 'apns_voip', 'apple-1')
      allow(Apnotic::Connection).to receive(:new).and_raise(SocketError)

      described_class.new(call: call).perform('ring')

      expect(call.reload.ring_state['unreached_user_ids']).to eq([agent.id])
    end

    it 'does not ring for a call that stopped ringing before the job ran' do
      subscribe(agent, 'apns_voip', 'apple-1')
      call.update!(status: 'failed')

      described_class.new(call: call).perform('ring')

      expect(apple_connection).not_to have_received(:push)
      expect(call.reload.ring_state['rung_devices']).to be_nil
    end

    it 'keeps the ring record when meta is saved from a copy of the call loaded before the ring' do
      subscribe(agent, 'apns_voip', 'apple-1')
      earlier_copy = Call.find(call.id)

      described_class.new(call: call).perform('ring')
      earlier_copy.update!(twilio_conference_sid: 'CF999')

      expect(call.reload.meta).to include('twilio_conference_sid' => 'CF999')
      expect(call.ring_state['rung_devices']).to eq('apns_voip' => ['apple-1'], 'fcm' => [])
    end

    it 'rings the agents recorded when the ring started, not a later assignee' do
      call.update!(ring_state: { 'ring_recipient_ids' => [agent.id] })
      conversation.update!(assignee: other_agent)
      subscribe(agent, 'apns_voip', 'apple-1')
      subscribe(other_agent, 'apns_voip', 'apple-2')

      described_class.new(call: call).perform('ring')

      expect(apple_connection).to have_received(:push).once
      expect(call.reload.ring_state['rung_devices']).to eq('apns_voip' => ['apple-1'], 'fcm' => [])
    end

    it 'records the agents chosen for the ring even when none of them has a phone' do
      described_class.new(call: call).perform('ring')

      expect(call.reload.ring_state['ring_recipient_ids']).to contain_exactly(agent.id, other_agent.id)
    end

    it 'rings and records the same agents even if the conversation is reassigned meanwhile' do
      subscribe(agent, 'apns_voip', 'apple-1')
      subscribe(other_agent, 'apns_voip', 'apple-2')
      allow(NotificationSubscription).to receive(:fcm).and_wrap_original do |original|
        conversation.update!(assignee: other_agent)
        original.call
      end

      described_class.new(call: call).perform('ring')

      expect(call.reload.ring_state['ring_recipient_ids']).to contain_exactly(agent.id, other_agent.id)
      expect(apple_connection).to have_received(:push).twice
    end

    it 'follows the ring with a cancel when the call ended while the pushes were in flight' do
      subscribe(agent, 'fcm', 'android-1', platform: 'Android')
      allow(fcm_client).to receive(:send_v1) do
        Call.where(id: call.id).update_all(status: 'rejected') # rubocop:disable Rails/SkipsModelValidations
        { status_code: 200, body: '' }
      end

      described_class.new(call: call).perform('ring')

      expect(fcm_client).to have_received(:send_v1).with(hash_including(data: hash_including('type' => 'voice_call.cancel'))).once
    end

    it 'follows the ring with a cancel when the call was answered while the pushes were in flight' do
      subscribe(agent, 'fcm', 'android-1', platform: 'Android')
      allow(fcm_client).to receive(:send_v1) do
        Call.where(id: call.id).update_all(status: 'in_progress') # rubocop:disable Rails/SkipsModelValidations
        { status_code: 200, body: '' }
      end

      described_class.new(call: call).perform('ring')

      expect(fcm_client).to have_received(:send_v1).with(hash_including(data: hash_including('type' => 'voice_call.cancel'))).once
    end

    it 'still follows the ring with a cancel when a cancel already removed the stored tokens' do
      subscribe(agent, 'fcm', 'android-1', platform: 'Android')
      allow(fcm_client).to receive(:send_v1) do |args|
        if args[:data]['type'] == 'voice_call.incoming'
          Call.where(id: call.id).update_all(status: 'in_progress', ring_state: {}) # rubocop:disable Rails/SkipsModelValidations
        end
        { status_code: 200, body: '' }
      end

      described_class.new(call: call).perform('ring')

      expect(fcm_client).to have_received(:send_v1)
        .with(hash_including(token: 'android-1', data: hash_including('type' => 'voice_call.cancel'))).once
    end

    it 'sends to the app bundle when the bundle ID is cleared' do
      config['APNS_VOIP_BUNDLE_ID'] = ''
      subscribe(agent, 'apns_voip', 'apple-1')

      described_class.new(call: call).perform('ring')

      expect(apple_connection).to have_received(:push).once do |notification|
        expect(notification.topic).to eq('com.chatwoot.app.voip')
      end
    end

    it 'fails loudly on an APNs environment it does not know' do
      config['APNS_VOIP_ENVIRONMENT'] = 'prod'
      subscribe(agent, 'apns_voip', 'apple-1')

      expect { described_class.new(call: call).perform('ring') }.to raise_error(ArgumentError, /APNS_VOIP_ENVIRONMENT/)
      expect(apple_connection).not_to have_received(:push)
    end

    it 'sends to Android phones a batch at a time' do
      stub_const('Voice::VoipPushService::ANDROID_BATCH_SIZE', 2)
      5.times { |i| subscribe(agent, 'fcm', "android-#{i}", platform: 'Android') }
      allow(Thread).to receive(:new).and_call_original

      described_class.new(call: call).perform('ring')

      expect(fcm_client).to have_received(:send_v1).exactly(5).times
      expect(Thread).to have_received(:new).exactly(7).times
    end

    it 'does nothing without any registered phone' do
      described_class.new(call: call).perform('ring')

      expect(apple_connection).not_to have_received(:push)
      expect(fcm_client).not_to have_received(:send_v1)
      expect(call.reload.ring_state['rung_devices']).to be_nil
    end

    it 'skips Apple quietly when APNs is not configured at all' do
      config.except!('APNS_VOIP_KEY', 'APNS_VOIP_KEY_ID', 'APNS_VOIP_TEAM_ID')
      subscribe(agent, 'apns_voip', 'apple-1')
      subscribe(agent, 'fcm', 'android-1', platform: 'Android')
      allow(ChatwootExceptionTracker).to receive(:new).and_call_original

      described_class.new(call: call).perform('ring')

      expect(Apnotic::Connection).not_to have_received(:new)
      expect(ChatwootExceptionTracker).not_to have_received(:new)
      expect(fcm_client).to have_received(:send_v1).once
    end

    it 'does not ring an agent whose status is busy or offline' do
      subscribe(agent, 'apns_voip', 'apple-1')
      subscribe(other_agent, 'apns_voip', 'apple-2')
      AccountUser.find_by(account: account, user: other_agent).update!(availability: :busy)

      described_class.new(call: call).perform('ring')

      expect(apple_connection).to have_received(:push).once
      expect(call.reload.ring_state['ring_recipient_ids']).to eq([agent.id])
    end

    it 'skips Android and reports it when Firebase is only partly configured and the relay is off' do
      config.delete('FIREBASE_CREDENTIALS')
      subscribe(agent, 'apns_voip', 'apple-1')
      subscribe(agent, 'fcm', 'android-1', platform: 'Android')
      tracker = instance_double(ChatwootExceptionTracker, capture_exception: nil)
      allow(ChatwootExceptionTracker).to receive(:new).and_return(tracker)

      with_modified_env(ENABLE_PUSH_RELAY_SERVER: 'false') { described_class.new(call: call).perform('ring') }

      expect(fcm_client).not_to have_received(:send_v1)
      expect(ChatwootExceptionTracker).to have_received(:new)
        .with(an_instance_of(ArgumentError).and(having_attributes(message: /FIREBASE_CREDENTIALS/)))
      expect(apple_connection).to have_received(:push).once
    end

    it 'skips Apple and reports it when APNs is only partly configured' do
      config.delete('APNS_VOIP_KEY')
      subscribe(agent, 'apns_voip', 'apple-1')
      subscribe(agent, 'fcm', 'android-1', platform: 'Android')
      tracker = instance_double(ChatwootExceptionTracker, capture_exception: nil)
      allow(ChatwootExceptionTracker).to receive(:new).and_return(tracker)

      described_class.new(call: call).perform('ring')

      expect(Apnotic::Connection).not_to have_received(:new)
      expect(ChatwootExceptionTracker).to have_received(:new).with(an_instance_of(ArgumentError).and(having_attributes(message: /APNS_VOIP_KEY\b/)))
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
      call.update!(status: 'no_answer', ring_state: { 'rung_devices' => { 'apns_voip' => ['apple-1'], 'fcm' => %w[android-1 android-2] } })
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
      call.update!(ring_state: { 'rung_devices' => { 'apns_voip' => ['apple-1'], 'fcm' => [] } })

      described_class.new(call: call).perform('cancel')

      expect(fcm_client).not_to have_received(:send_v1)
    end

    it 'forgets the device tokens once the ring is cancelled, keeping the agents rung' do
      call.update!(ring_state: call.ring_state.merge('ring_recipient_ids' => [agent.id]))

      described_class.new(call: call).perform('cancel')

      expect(call.reload.ring_state).to eq('ring_recipient_ids' => [agent.id])
    end

    it 'forgets the device tokens of an outbound call too' do
      call.update!(direction: :outgoing)

      described_class.new(call: call).perform('cancel')

      expect(call.reload.ring_state).not_to have_key('rung_devices')
    end
  end

  describe 'through the Chatwoot Hub relay' do
    let(:hub_fcm) { stub_request(:post, ChatwootHub.push_notification_url).to_return(body: { status_code: 200, body: '' }.to_json) }
    let(:hub_voip) { stub_request(:post, ChatwootHub.voip_push_url).to_return { |request| { body: voip_results(request, 200).to_json } } }

    before do
      config.except!('APNS_VOIP_KEY', 'APNS_VOIP_KEY_ID', 'APNS_VOIP_TEAM_ID', 'FIREBASE_PROJECT_ID', 'FIREBASE_CREDENTIALS')
      allow(ChatwootHub).to receive(:push_relay_token).and_return('relay-token')
      hub_fcm
      hub_voip
    end

    def voip_results(request, status)
      { results: JSON.parse(request.body)['tokens'].index_with { { status: status, reason: nil } } }
    end

    def hub_message(request)
      JSON.parse(request.body)['fcm_options']
    end

    it 'rings Android phones with the hub relaying the data message to FCM' do
      subscribe(agent, 'fcm', 'android-1', platform: 'Android')

      described_class.new(call: call).perform('ring')

      expect(Notification::FcmService).not_to have_received(:new)
      expect(hub_fcm.with do |request|
        hub_message(request)['token'] == 'android-1' && hub_message(request)['data']['type'] == 'voice_call.incoming' &&
          hub_message(request)['android'] == { 'priority' => 'high', 'ttl' => '45s' } &&
          JSON.parse(request.body)['installation_identifier'] == ChatwootHub.installation_identifier
      end).to have_been_made.once
      expect(call.reload.ring_state['rung_devices']).to eq('apns_voip' => [], 'fcm' => ['android-1'])
      expect(described_class.new(call: call).ringable_user_ids).to eq([agent.id])
    end

    it 'removes Android phones FCM reports unregistered through the hub' do
      subscribe(agent, 'fcm', 'android-gone', platform: 'Android')
      stub_request(:post, ChatwootHub.push_notification_url)
        .to_return(body: { status_code: 404, body: '{"error":{"details":[{"errorCode":"UNREGISTERED"}]}}' }.to_json)

      expect { described_class.new(call: call).perform('ring') }.to change(NotificationSubscription, :count).by(-1)
    end

    it 'treats an Android phone the hub could not deliver to as not reached' do
      subscribe(agent, 'fcm', 'android-1', platform: 'Android')
      stub_request(:post, ChatwootHub.push_notification_url).to_return(status: 502)

      described_class.new(call: call).perform('ring')

      expect(call.reload.ring_state['unreached_user_ids']).to eq([agent.id])
      expect(NotificationSubscription.where(user: agent)).to exist
    end

    it 'sends the Android cancel through the hub' do
      call.update!(status: 'no_answer', ring_state: { 'rung_devices' => { 'apns_voip' => [], 'fcm' => ['android-1'] } })

      described_class.new(call: call).perform('cancel')

      expect(hub_fcm.with { |request| hub_message(request)['data']['type'] == 'voice_call.cancel' }).to have_been_made.once
    end

    it 'rings iPhones with the hub sending the VoIP pushes, authenticated with the relay token' do
      subscribe(agent, 'apns_voip', 'apple-1')
      subscribe(other_agent, 'apns_voip', 'apple-2')

      described_class.new(call: call).perform('ring')

      expect(Apnotic::Connection).not_to have_received(:new)
      expect(hub_voip.with(headers: { 'Authorization' => 'Bearer relay-token' }) do |request|
        body = JSON.parse(request.body)
        body['tokens'].sort == %w[apple-1 apple-2] && body['payload']['type'] == 'voice_call.incoming' && body['payload']['id'] == call.id
      end).to have_been_made.once
      expect(described_class.new(call: call).ringable_user_ids).to contain_exactly(agent.id, other_agent.id)
    end

    it 'removes iPhones APNs reports gone through the hub and treats failures as not reached' do
      subscribe(agent, 'apns_voip', 'apple-gone')
      subscribe(other_agent, 'apns_voip', 'apple-failed')
      stub_request(:post, ChatwootHub.voip_push_url)
        .to_return(body: { results: { 'apple-gone' => { status: 410, reason: 'Unregistered' }, 'apple-failed' => { status: 0 } } }.to_json)

      expect { described_class.new(call: call).perform('ring') }.to change(NotificationSubscription, :count).by(-1)
      expect(call.reload.ring_state['unreached_user_ids']).to contain_exactly(agent.id, other_agent.id)
    end

    it 'treats every iPhone as not reached when the hub refuses the request' do
      subscribe(agent, 'apns_voip', 'apple-1')
      stub_request(:post, ChatwootHub.voip_push_url).to_return(status: 401)

      described_class.new(call: call).perform('ring')

      expect(call.reload.ring_state['unreached_user_ids']).to eq([agent.id])
    end

    it 'does not ring iPhones before the hub has issued a relay token' do
      allow(ChatwootHub).to receive(:push_relay_token).and_return(nil)
      subscribe(agent, 'apns_voip', 'apple-1')

      described_class.new(call: call).perform('ring')

      expect(hub_voip).not_to have_been_made
      expect(described_class.new(call: call).ringable_user_ids).to be_empty
    end

    it 'rings nothing when the relay is off' do
      subscribe(agent, 'apns_voip', 'apple-1')
      subscribe(agent, 'fcm', 'android-1', platform: 'Android')

      with_modified_env(ENABLE_PUSH_RELAY_SERVER: 'false') do
        described_class.new(call: call).perform('ring')
        expect(described_class.new(call: call).ringable_user_ids).to be_empty
      end

      expect(hub_fcm).not_to have_been_made
      expect(hub_voip).not_to have_been_made
    end
  end
end
