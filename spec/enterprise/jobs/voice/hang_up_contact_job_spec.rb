# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Voice::HangUpContactJob do
  let(:account) { create(:account) }
  let(:channel) { create(:channel_twilio_sms, :with_voice, account: account, phone_number: '+15551239999') }
  let(:conversation) { create(:conversation, account: account, inbox: channel.inbox) }
  let(:call) { create(:call, conversation: conversation, status: 'no_answer') }
  let(:conference) { instance_double(Voice::Provider::Twilio::ConferenceService, terminate_call: nil) }

  before do
    allow(Twilio::VoiceWebhookSetupService).to receive(:new)
      .and_return(instance_double(Twilio::VoiceWebhookSetupService, perform: "AP#{SecureRandom.hex(8)}"))
    allow(Voice::Provider::Twilio::ConferenceService).to receive(:new).and_return(conference)
  end

  it 'hangs up the contact leg of the call' do
    described_class.perform_now(call.id)

    expect(conference).to have_received(:terminate_call)
  end

  it 'retries when Twilio cannot be reached' do
    allow(conference).to receive(:terminate_call).and_raise(Twilio::REST::TwilioError)

    expect { described_class.perform_now(call.id) }.to have_enqueued_job(described_class).with(call.id)
  end
end
