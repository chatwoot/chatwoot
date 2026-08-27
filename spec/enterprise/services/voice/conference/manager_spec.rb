require 'rails_helper'

RSpec.describe Voice::Conference::Manager do
  let(:account) { create(:account) }
  let(:channel) { create(:channel_twilio_sms, :with_voice, account: account, phone_number: '+15551238888') }
  let(:conversation) { create(:conversation, account: account, inbox: channel.inbox) }
  let(:call) { create(:call, account: account, inbox: channel.inbox, conversation: conversation, contact: conversation.contact) }
  let(:conference_service) { instance_double(Voice::Provider::Twilio::ConferenceService, start_recording: true, stop_recording: true) }

  before do
    allow(Twilio::VoiceWebhookSetupService).to receive(:new)
      .and_return(instance_double(Twilio::VoiceWebhookSetupService, perform: "AP#{SecureRandom.hex(16)}"))
    allow(Voice::Provider::Twilio::ConferenceService).to receive(:new).and_return(conference_service)
  end

  def start_conference
    described_class.new(call: call, event: 'start', participant_label: 'contact').process
  end

  describe 'conference start' do
    it 'stops a recording the contact leg started when the inbox has since been turned off' do
      call.update!(recording_started: true)
      channel.update!(provider_config: channel.provider_config.merge('recording_enabled' => false))

      start_conference

      expect(conference_service).to have_received(:stop_recording)
    end

    it 'starts a recording when the contact leg was not recording but the inbox has since been turned on' do
      call.update!(recording_started: false)

      start_conference

      expect(conference_service).to have_received(:start_recording)
    end

    it 'leaves the recording alone when it already matches the inbox setting' do
      call.update!(recording_started: true)

      start_conference

      expect(Voice::Provider::Twilio::ConferenceService).not_to have_received(:new)
    end
  end
end
