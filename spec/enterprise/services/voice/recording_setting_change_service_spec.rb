require 'rails_helper'

RSpec.describe Voice::RecordingSettingChangeService do
  let(:account) { create(:account) }
  let(:channel) { create(:channel_twilio_sms, :with_voice, account: account, phone_number: '+15551238888') }
  let(:inbox) { channel.inbox }
  let(:conversation) { create(:conversation, account: account, inbox: inbox) }
  let(:conference_service) { instance_double(Voice::Provider::Twilio::ConferenceService, stop_recording: true) }
  let!(:live_call) do
    create(:call, account: account, inbox: inbox, conversation: conversation, contact: conversation.contact, status: 'in_progress')
  end

  before do
    allow(Twilio::VoiceWebhookSetupService).to receive(:new)
      .and_return(instance_double(Twilio::VoiceWebhookSetupService, perform: "AP#{SecureRandom.hex(16)}"))
    allow(Voice::Provider::Twilio::ConferenceService).to receive(:new).and_return(conference_service)
    allow(ActionCable.server).to receive(:broadcast)
    create(:call, account: account, inbox: inbox, conversation: conversation, contact: conversation.contact,
                  status: 'completed', provider_call_id: 'CA_done')
  end

  it 'stops recording on every active Twilio call when recording is turned off' do
    channel.update!(provider_config: channel.provider_config.merge('recording_enabled' => false))

    described_class.new(inbox: inbox).perform

    expect(Voice::Provider::Twilio::ConferenceService).to have_received(:new).with(call: live_call).once
    expect(conference_service).to have_received(:stop_recording).once
    expect(ActionCable.server).to have_received(:broadcast).with(
      "account_#{account.id}",
      { event: 'voice_call.recording_setting', data: { account_id: account.id, inbox_id: inbox.id, recording_enabled: false } }
    )
  end

  it 'only broadcasts when recording is turned on' do
    described_class.new(inbox: inbox).perform

    expect(Voice::Provider::Twilio::ConferenceService).not_to have_received(:new)
    expect(ActionCable.server).to have_received(:broadcast).with(
      "account_#{account.id}", hash_including(data: hash_including(recording_enabled: true))
    )
  end
end
