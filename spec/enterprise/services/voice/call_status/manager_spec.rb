require 'rails_helper'

RSpec.describe Voice::CallStatus::Manager do
  let(:account) { create(:account) }
  let(:channel) { create(:channel_twilio_sms, :with_voice, account: account) }
  let(:conversation) { create(:conversation, account: account, inbox: channel.inbox) }
  let(:call) do
    create(:call, account: account, inbox: channel.inbox, conversation: conversation,
                  contact: conversation.contact, status: 'in_progress')
  end
  let(:manager) { described_class.new(call: call) }

  it 'blocks terminal provider transitions while agent teardown is pending' do
    call.update!(meta: call.meta.merge('agent_termination_pending' => true))

    manager.process_status_update('completed')

    expect(call.reload.status).to eq('in_progress')
  end

  it 'allows the intended local terminal transition during agent teardown' do
    call.update!(meta: call.meta.merge('agent_termination_pending' => true))

    manager.process_status_update('completed', allow_during_termination: true)

    expect(call.reload.status).to eq('completed')
  end
end
