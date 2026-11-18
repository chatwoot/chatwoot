require 'rails_helper'

RSpec.describe Voice::AddedRingPushService do
  let(:account) { create(:account) }
  let(:channel) { create(:channel_twilio_sms, :with_voice, account: account) }
  let(:inbox) { channel.inbox }
  let(:first_agent) { create(:user, account: account, role: :agent) }
  let(:added_agent) { create(:user, account: account, role: :agent) }
  let(:conversation) { create(:conversation, account: account, inbox: inbox) }
  let(:call) do
    create(:call, account: account, inbox: inbox, conversation: conversation, contact: conversation.contact,
                  ring_state: { 'ring_recipient_ids' => [first_agent.id, added_agent.id], 'rung_user_ids' => [first_agent.id],
                                'unreached_user_ids' => [], 'rung_devices' => { 'apns_voip' => ['apple-first'], 'fcm' => [] } })
  end
  let(:config) do
    { 'APNS_VOIP_KEY' => 'p8-contents', 'APNS_VOIP_KEY_ID' => 'KEY1', 'APNS_VOIP_TEAM_ID' => 'TEAM1',
      'FIREBASE_PROJECT_ID' => 'project', 'FIREBASE_CREDENTIALS' => '{}' }
  end
  let(:apple_connection) { instance_double(Apnotic::Connection, push: instance_double(Apnotic::Response, status: '200', body: ''), close: nil) }
  let(:fcm_client) { instance_double(FCM, send_v1: { status_code: 200, body: '' }) }

  before do
    allow(Twilio::VoiceWebhookSetupService).to receive(:new)
      .and_return(instance_double(Twilio::VoiceWebhookSetupService, perform: "AP#{SecureRandom.hex(8)}"))
    allow(GlobalConfigService).to receive(:load) { |key, default| config.fetch(key, default) }
    allow(Apnotic::Connection).to receive(:new).and_return(apple_connection)
    allow(Notification::FcmService).to receive(:new).and_return(instance_double(Notification::FcmService, fcm_client: fcm_client))
    create(:notification_subscription, user: added_agent, subscription_type: 'fcm', identifier: 'fcm:android-added',
                                       subscription_attributes: { push_token: 'android-added', device_id: 'd1', devicePlatform: 'android' })
  end

  it "rings the added agent's phones and adds them to the devices the cancel reaches" do
    described_class.new(call: call, users: [added_agent]).perform

    expect(fcm_client).to have_received(:send_v1).with(hash_including(token: 'android-added')).once
    expect(apple_connection).not_to have_received(:push)
    expect(call.reload.ring_state).to include('rung_user_ids' => [first_agent.id, added_agent.id],
                                              'rung_devices' => { 'apns_voip' => ['apple-first'], 'fcm' => ['android-added'] })
  end

  it 'cancels only its own phones when the call is answered while its pushes are in flight' do
    call.update!(ring_state: call.ring_state.merge('rung_devices' => { 'apns_voip' => [], 'fcm' => ['android-first'] }))
    allow(fcm_client).to receive(:send_v1) do |message|
      Call.find(call.id).update!(status: 'in_progress') if message[:data]['type'] != 'voice_call.cancel'
      { status_code: 200, body: '' }
    end

    described_class.new(call: call, users: [added_agent]).perform

    expect(fcm_client).to have_received(:send_v1).with(hash_including(token: 'android-added', data: hash_including('type' => 'voice_call.cancel')))
    expect(fcm_client).not_to have_received(:send_v1).with(hash_including(token: 'android-first'))
    expect(call.reload.ring_state['rung_devices']['fcm']).to contain_exactly('android-first', 'android-added')
  end

  it 'rings nobody once the call stopped ringing' do
    call.update!(status: 'in_progress')

    described_class.new(call: call, users: [added_agent]).perform

    expect(fcm_client).not_to have_received(:send_v1)
    expect(call.reload.ring_state['rung_user_ids']).to eq([first_agent.id])
  end
end
