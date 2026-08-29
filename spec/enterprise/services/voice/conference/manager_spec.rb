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

  it 'records the confirmed agent join status with the agent claim' do
    described_class.new(
      call: call,
      event: 'join',
      participant_label: "agent-#{agent.id}-account-#{account.id}",
      participant_call_sid: 'CA_AGENT_CONFIRMED'
    ).process

    call.reload
    expect(call.status).to eq('in_progress')
    expect(call.accepted_by_agent_id).to eq(agent.id)
    expect(call.started_at).to be_present
  end

  it 'uses the original participant timestamp when replaying a deferred join' do
    join_timestamp = 1_800_000_000

    described_class.new(
      call: call,
      event: 'join',
      participant_label: "agent-#{agent.id}-account-#{account.id}",
      participant_call_sid: 'CA_AGENT_REPLAY',
      participant_timestamp: join_timestamp
    ).process

    expect(call.reload.started_at).to eq(Time.zone.at(join_timestamp))
  end

  it 'defers a late agent join while agent teardown is pending' do
    call.update!(meta: call.meta.merge('agent_termination_token' => 'termination-1'))
    allow(call).to receive(:broadcast_voice_call_event)

    expect do
      described_class.new(
        call: call,
        event: 'join',
        participant_label: "agent-#{agent.id}-account-#{account.id}",
        participant_call_sid: 'CA_AGENT_1'
      ).process
    end.to have_enqueued_job(Voice::ReconcileSuppressedTerminationJob).with(call.id)

    call.reload
    expect(call.status).to eq('ringing')
    expect(call.accepted_by_agent_id).to be_nil
    expect(call.accepted_broadcast_at).to be_nil
    expect(call.meta['agent_termination_pending_join']).to include(
      'participant_label' => "agent-#{agent.id}-account-#{account.id}",
      'participant_call_sid' => 'CA_AGENT_1',
      'termination_token' => 'termination-1',
      'timestamp' => be_present
    )
    expect(call).not_to have_received(:broadcast_voice_call_event)
  end

  it 'defers the join if teardown is claimed after the initial guard check' do
    manager = described_class.new(
      call: call,
      event: 'join',
      participant_label: "agent-#{agent.id}-account-#{account.id}",
      participant_call_sid: 'CA_AGENT_RACE'
    )
    allow(manager).to receive(:defer_join_if_termination_pending!) do
      call.update!(meta: Voice::CallTerminationGuard.claim_meta(call, token: 'termination-race'))
      false
    end

    manager.process

    call.reload
    expect(call.status).to eq('ringing')
    expect(call.accepted_by_agent_id).to be_nil
    expect(call.meta['agent_termination_pending_join']).to include('participant_call_sid' => 'CA_AGENT_RACE')
  end

  it 'consumes the matching delayed agent leave regardless of delivery time' do
    Voice::CallTerminationGuard.suppress_local_disconnect!(call, 'CA_AGENT_1')

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

  it 'does not suppress a different tab for the same agent' do
    Voice::CallTerminationGuard.suppress_local_disconnect!(call, 'CA_OLD_TAB')

    described_class.new(
      call: call,
      event: 'leave',
      participant_label: "agent-#{agent.id}-account-#{account.id}",
      participant_call_sid: 'CA_NEW_TAB'
    ).process

    expect(call.reload.status).to eq('no_answer')
  end
end
