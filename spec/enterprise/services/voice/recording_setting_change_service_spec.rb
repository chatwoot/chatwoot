require 'rails_helper'

RSpec.describe Voice::RecordingSettingChangeService do
  let(:account) { create(:account) }
  let(:channel) { create(:channel_twilio_sms, :with_voice, account: account, phone_number: '+15551238888') }
  let(:inbox) { channel.inbox }
  let(:conversation) { create(:conversation, account: account, inbox: inbox) }
  let(:conference_service) { instance_double(Voice::Provider::Twilio::ConferenceService, start_recording: true, stop_recording: true) }
  let!(:live_call) do
    create(:call, account: account, inbox: inbox, conversation: conversation, contact: conversation.contact,
                  status: 'in_progress', recording_started: true)
  end

  before do
    allow(Twilio::VoiceWebhookSetupService).to receive(:new)
      .and_return(instance_double(Twilio::VoiceWebhookSetupService, perform: "AP#{SecureRandom.hex(16)}"))
    allow(Voice::Provider::Twilio::ConferenceService).to receive(:new).and_return(conference_service)
    allow(ActionCable.server).to receive(:broadcast)
    create(:call, account: account, inbox: inbox, conversation: conversation, contact: conversation.contact,
                  status: 'ringing', provider_call_id: 'CA_ringing', recording_started: true)
  end

  it 'stops recording on calls in progress and broadcasts when recording is turned off' do
    channel.update!(provider_config: channel.provider_config.merge('recording_enabled' => false))

    described_class.new(inbox: inbox).perform

    expect(Voice::Provider::Twilio::ConferenceService).to have_received(:new).with(call: live_call).once
    expect(conference_service).to have_received(:stop_recording).once
    expect(ActionCable.server).to have_received(:broadcast).with(
      "account_#{account.id}",
      { event: 'voice_call.recording_setting', data: { account_id: account.id, inbox_id: inbox.id, recording_enabled: false } }
    )
  end

  it 'starts recording on calls in progress that are not recording when recording is turned on' do
    live_call.update!(recording_started: false)

    described_class.new(inbox: inbox).perform

    expect(Voice::Provider::Twilio::ConferenceService).to have_received(:new).with(call: live_call).once
    expect(conference_service).to have_received(:start_recording).once
    expect(ActionCable.server).to have_received(:broadcast).with(
      "account_#{account.id}", hash_including(data: hash_including(recording_enabled: true))
    )
  end

  it 'leaves calls whose recording already matches the setting alone' do
    described_class.new(inbox: inbox).perform

    expect(Voice::Provider::Twilio::ConferenceService).not_to have_received(:new)
  end
end
