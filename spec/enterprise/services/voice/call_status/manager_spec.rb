require 'rails_helper'

RSpec.describe Voice::CallStatus::Manager do
  let(:account) { create(:account) }
  let(:channel) { create(:channel_twilio_sms, :with_voice, account: account) }
  let(:conversation) { create(:conversation, account: account, inbox: channel.inbox) }
  let(:call) do
    create(:call, account: account, inbox: channel.inbox, conversation: conversation,
                  contact: conversation.contact, status: 'ringing')
  end
  let(:manager) { described_class.new(call: call) }

  it 'blocks terminal provider transitions while agent teardown is pending' do
    call.update!(meta: call.meta.merge('agent_termination_token' => 'termination-1'))

    manager.process_status_update('completed')

    expect(call.reload.status).to eq('ringing')
  end

  it 'blocks late progress transitions while agent teardown is pending' do
    call.update!(meta: call.meta.merge('agent_termination_token' => 'termination-1'))

    manager.process_status_update('in_progress')

    call.reload
    expect(call.status).to eq('ringing')
    expect(call.started_at).to be_nil
  end

  it 'allows provider progress after an abandoned teardown guard expires' do
    call.update!(
      meta: call.meta.merge(
        'agent_termination_token' => 'abandoned-token',
        'agent_termination_started_at' => 3.minutes.ago.to_i
      )
    )

    manager.process_status_update('in_progress')

    call.reload
    expect(call.status).to eq('in_progress')
    expect(call.meta['agent_termination_token']).to be_nil
    expect(call.meta['agent_termination_started_at']).to be_nil
  end

  it 'allows the snapshotted local terminal transition during agent teardown' do
    call.update!(meta: call.meta.merge('agent_termination_token' => 'termination-1'))

    manager.process_status_update('rejected', allow_during_termination: true)

    expect(call.reload.status).to eq('rejected')
  end
end
