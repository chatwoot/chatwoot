require 'rails_helper'

RSpec.describe Voice::RecordingSettingChangeService do
  let(:account) { create(:account) }
  let(:channel) { create(:channel_twilio_sms, :with_voice, account: account, phone_number: '+15551238888') }
  let(:inbox) { channel.inbox }
  let(:conversation) { create(:conversation, account: account, inbox: inbox) }
  let(:twilio_client) { instance_double(Twilio::REST::Client) }
  let(:recording_context) { instance_double(Twilio::REST::Api::V2010::AccountContext::ConferenceContext::RecordingContext, update: true) }
  let(:conference_context) { instance_double(Twilio::REST::Api::V2010::AccountContext::ConferenceContext, recordings: recording_context) }

  before do
    allow(Twilio::VoiceWebhookSetupService).to receive(:new)
      .and_return(instance_double(Twilio::VoiceWebhookSetupService, perform: "AP#{SecureRandom.hex(16)}"))
    allow(Twilio::REST::Client).to receive(:new).and_return(twilio_client)
    allow(twilio_client).to receive(:conferences).with('CF_live').and_return(conference_context)
    allow(ActionCable.server).to receive(:broadcast)
    create(:call, account: account, inbox: inbox, conversation: conversation, contact: conversation.contact,
                  status: 'in_progress', twilio_conference_sid: 'CF_live')
    create(:call, account: account, inbox: inbox, conversation: conversation, contact: conversation.contact,
                  status: 'completed', twilio_conference_sid: 'CF_done', provider_call_id: 'CA_done')
  end

  it 'stops in-progress Twilio conference recordings when recording is turned off' do
    channel.update!(provider_config: channel.provider_config.merge('recording_enabled' => false))

    described_class.new(inbox: inbox).perform

    expect(conference_context).to have_received(:recordings).with('Twilio.CURRENT')
    expect(recording_context).to have_received(:update).with(status: 'stopped')
    expect(ActionCable.server).to have_received(:broadcast).with(
      "account_#{account.id}", hash_including(data: hash_including(inbox_id: inbox.id, recording_enabled: false))
    )
  end

  it 'only broadcasts when recording is turned on' do
    described_class.new(inbox: inbox).perform

    expect(twilio_client).not_to have_received(:conferences)
    expect(ActionCable.server).to have_received(:broadcast).with(
      "account_#{account.id}", hash_including(data: hash_including(recording_enabled: true))
    )
  end
end
