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
      participant_label: "agent-#{agent.id}-account-#{account.id}"
    ).process

    call.reload
    expect(call.status).to eq('ringing')
    expect(call.accepted_by_agent_id).to be_nil
    expect(call.accepted_broadcast_at).to be_nil
    expect(call).not_to have_received(:broadcast_voice_call_event)
  end

  it 'ignores the local leave callback after a failed provider teardown' do
    Voice::CallTerminationGuard.suppress_local_disconnect!(call)

    described_class.new(
      call: call,
      event: 'leave',
      participant_label: "agent-#{agent.id}-account-#{account.id}"
    ).process

    expect(call.reload.status).to eq('ringing')
  end

  it 'processes leave callbacks again after disconnect suppression expires' do
    now = Time.zone.now
    Voice::CallTerminationGuard.suppress_local_disconnect!(call, now: now - 31.seconds)

    described_class.new(
      call: call,
      event: 'leave',
      participant_label: "agent-#{agent.id}-account-#{account.id}"
    ).process

    expect(call.reload.status).to eq('no_answer')
  end
end
