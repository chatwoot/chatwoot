require 'rails_helper'

RSpec.describe Voice::Conference::Manager do
  let(:account) { create(:account) }
  let(:channel) { create(:channel_twilio_sms, :with_voice, account: account, phone_number: '+15551238888') }
  let(:conversation) { create(:conversation, account: account, inbox: channel.inbox) }
  let(:call) { create(:call, account: account, inbox: channel.inbox, conversation: conversation, contact: conversation.contact) }
  let(:conference_service) { instance_double(Voice::Provider::Twilio::ConferenceService, stop_recording: true) }

  before do
    allow(Twilio::VoiceWebhookSetupService).to receive(:new)
      .and_return(instance_double(Twilio::VoiceWebhookSetupService, perform: "AP#{SecureRandom.hex(16)}"))
    allow(Voice::Provider::Twilio::ConferenceService).to receive(:new).and_return(conference_service)
  end

  describe 'conference start' do
    it 'stops the recording when the inbox has recording turned off' do
      channel.update!(provider_config: channel.provider_config.merge('recording_enabled' => false))

      described_class.new(call: call, event: 'start', participant_label: 'contact').process

      expect(conference_service).to have_received(:stop_recording)
    end

    it 'leaves the recording alone when recording is on' do
      described_class.new(call: call, event: 'start', participant_label: 'contact').process

      expect(Voice::Provider::Twilio::ConferenceService).not_to have_received(:new)
    end
  end
end
