require 'rails_helper'

RSpec.describe Voice::Conference::Manager do
  let(:account) { create(:account) }
  let(:channel) { create(:channel_twilio_sms, :with_voice, account: account) }
  let(:conversation) { create(:conversation, account: account, inbox: channel.inbox) }
  let(:agent) { create(:user, account: account) }
  let(:call) do
    create(:call, account: account, inbox: channel.inbox, conversation: conversation,
                  contact: conversation.contact, status: 'ringing')
  end

  it 'ignores a late agent join while agent teardown is pending' do
    call.update!(meta: call.meta.merge('agent_termination_token' => 'termination-1'))
    allow(call).to receive(:broadcast_voice_call_event)

    described_class.new(
      call: call,
      event: 'join',
      participant_label: "agent-#{agent.id}-account-#{account.id}",
      participant_call_sid: 'CA_AGENT_1'
    ).process

    call.reload
    expect(call.status).to eq('ringing')
    expect(call.accepted_by_agent_id).to be_nil
    expect(call.accepted_broadcast_at).to be_nil
    expect(call).not_to have_received(:broadcast_voice_call_event)
  end

  it 'consumes the matching delayed agent leave regardless of delivery time' do
    Voice::CallTerminationGuard.track_agent_participant!(call, 'CA_AGENT_1')
    Voice::CallTerminationGuard.suppress_local_disconnect!(call)

    described_class.new(
      call: call,
      event: 'leave',
      participant_label: "agent-#{agent.id}-account-#{account.id}",
      participant_call_sid: 'CA_AGENT_1'
    ).process

    call.reload
    expect(call.status).to eq('ringing')
    expect(call.meta['agent_disconnect_suppress_call_sid']).to be_nil
  end

  it 'does not suppress an unrelated participant leave' do
    Voice::CallTerminationGuard.track_agent_participant!(call, 'CA_AGENT_1')
    Voice::CallTerminationGuard.suppress_local_disconnect!(call)

    described_class.new(
      call: call,
      event: 'leave',
      participant_label: "agent-#{agent.id}-account-#{account.id}",
      participant_call_sid: 'CA_AGENT_2'
    ).process

    expect(call.reload.status).to eq('no_answer')
  end
end
