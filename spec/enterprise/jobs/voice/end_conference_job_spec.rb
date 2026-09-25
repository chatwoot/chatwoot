# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Voice::EndConferenceJob do
  let(:account) { create(:account) }
  let(:channel) { create(:channel_twilio_sms, :with_voice, account: account, phone_number: '+15551239999') }
  let(:conversation) { create(:conversation, account: account, inbox: channel.inbox) }
  let(:call) { create(:call, conversation: conversation, status: 'completed') }
  let(:conference) { instance_double(Voice::Provider::Twilio::ConferenceService, end_conference: nil) }

  before do
    allow(Twilio::VoiceWebhookSetupService).to receive(:new)
      .and_return(instance_double(Twilio::VoiceWebhookSetupService, perform: "AP#{SecureRandom.hex(8)}"))
    allow(Voice::Provider::Twilio::ConferenceService).to receive(:new).and_return(conference)
  end

  it 'ends the conference of the call' do
    described_class.perform_now(call.id)

    expect(Voice::Provider::Twilio::ConferenceService).to have_received(:new).with(call: call)
    expect(conference).to have_received(:end_conference)
  end

  it 'ignores a call that no longer exists' do
    described_class.perform_now(call.id + 1000)

    expect(conference).not_to have_received(:end_conference)
  end

  it 'retries when Twilio cannot be reached' do
    allow(conference).to receive(:end_conference).and_raise(Twilio::REST::TwilioError)

    expect { described_class.perform_now(call.id) }.to have_enqueued_job(described_class).with(call.id)
  end
end
