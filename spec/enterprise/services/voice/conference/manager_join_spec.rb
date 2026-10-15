# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Voice::Conference::Manager do
  let(:account) { create(:account) }
  let(:agent) { create(:user, account: account, role: :agent) }
  let(:channel) { create(:channel_twilio_sms, :with_voice, account: account, phone_number: '+15551239999') }
  let(:conversation) { create(:conversation, account: account, inbox: channel.inbox, assignee: agent) }
  let(:call) { create(:call, conversation: conversation, status: 'ringing') }
  let(:agent_label) { "agent-#{agent.id}-account-#{account.id}" }

  before do
    allow(Twilio::VoiceWebhookSetupService).to receive(:new)
      .and_return(instance_double(Twilio::VoiceWebhookSetupService, perform: "AP#{SecureRandom.hex(8)}"))
  end

  it 'counts a call as answered when the caller hangs up just after the join is claimed' do
    manager = described_class.new(call: call, event: 'join', participant_label: agent_label)
    conversation.update!(assignee: nil)
    allow(manager).to receive(:auto_assign_conversation!) do
      Voice::CallStatus::Manager.new(call: Call.find(call.id)).process_status_update('completed', timestamp: Time.zone.now.to_i)
    end

    manager.process

    expect(call.reload).to have_attributes(status: 'completed', missed?: false)
  end
end
