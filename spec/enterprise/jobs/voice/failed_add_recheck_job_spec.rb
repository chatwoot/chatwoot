# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Voice::FailedAddRecheckJob do
  let(:account) { create(:account) }
  let(:agent) { create(:user, account: account, role: :agent) }
  let(:channel) { create(:channel_twilio_sms, :with_voice, account: account, phone_number: '+15551239999') }
  let(:conversation) { create(:conversation, account: account, inbox: channel.inbox) }
  let(:label) { "agent-#{agent.id}-account-#{account.id}" }
  let(:conference) { instance_double(Voice::Provider::Twilio::ConferenceService, end_conference: nil, terminate_call: nil) }

  before do
    allow(Twilio::VoiceWebhookSetupService).to receive(:new)
      .and_return(instance_double(Twilio::VoiceWebhookSetupService, perform: "AP#{SecureRandom.hex(8)}"))
    allow(Voice::Provider::Twilio::ConferenceService).to receive(:new).and_return(conference)
  end

  def call_with(state, at:)
    create(:call, conversation: conversation, direction: :outgoing, status: 'ringing', accepted_by_agent: agent,
                  meta: { 'agent_legs' => { 'CA-old' => { 'state' => 'gone', 'at' => at }, 'CA-new' => { 'state' => state, 'at' => at } } })
  end

  it 'ends an outbound call whose new connection never joined' do
    call = call_with('joining', at: 2.minutes.ago.to_i)

    described_class.perform_now(call.id, label, 'CA-old')

    expect(call.reload.status).to eq('no_answer')
    expect(conference).to have_received(:end_conference)
  end

  it 'leaves the call to a new connection that joined' do
    call = call_with('joined', at: 2.minutes.ago.to_i)

    described_class.perform_now(call.id, label, 'CA-old')

    expect(call.reload.status).to eq('ringing')
    expect(conference).not_to have_received(:end_conference)
  end
end
