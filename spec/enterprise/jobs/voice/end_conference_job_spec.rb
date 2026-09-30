# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Voice::EndConferenceJob do
  let(:account) { create(:account) }
  let(:channel) { create(:channel_twilio_sms, :with_voice, account: account, phone_number: '+15551239999') }
  let(:conversation) { create(:conversation, account: account, inbox: channel.inbox) }
  let(:call) { create(:call, conversation: conversation, status: 'completed') }
  let(:conference) { instance_double(Voice::Provider::Twilio::ConferenceService, end_conference: nil, agents_remain?: false) }

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

  it 'leaves the conference running when another agent is still on the call' do
    allow(conference).to receive(:agents_remain?).and_return(true)

    described_class.perform_now(call.id, leaving_call_sid: 'CA-agent-1')

    expect(conference).to have_received(:agents_remain?).with(leaving_call_sid: 'CA-agent-1')
    expect(conference).not_to have_received(:end_conference)
  end

  it 'ends the conference and completes the call once the last agent is confirmed gone' do
    live = create(:call, conversation: conversation, status: 'in_progress', started_at: 1.minute.ago)
    allow(ActionCable.server).to receive(:broadcast)

    described_class.perform_now(live.id, leaving_call_sid: 'CA-agent-1')

    expect(conference).to have_received(:end_conference)
    expect(live.reload.status).to eq('completed')
  end

  it 'retries when Twilio cannot be reached' do
    allow(conference).to receive(:end_conference).and_raise(Twilio::REST::TwilioError)

    expect { described_class.perform_now(call.id) }.to have_enqueued_job(described_class).with(call.id)
  end
end
