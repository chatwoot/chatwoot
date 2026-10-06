require 'rails_helper'

RSpec.describe ConversationMonitors::SlackAlertJob do
  let(:account) { create(:account) }
  let(:monitor) { create(:conversation_monitor, account: account, slack_channel_id: 'C0ALERTS') }
  let(:conversation) { create(:conversation, account: account) }
  let(:service) { instance_double(ConversationMonitors::SlackAlertService, perform: true) }

  before { allow(ConversationMonitors::SlackAlertService).to receive(:new).and_return(service) }

  it 'sends the alert through the account Slack integration' do
    hook = create(:integrations_hook, account: account)

    described_class.perform_now(monitor.id, conversation.id)

    expect(ConversationMonitors::SlackAlertService).to have_received(:new).with(monitor: monitor, conversation: conversation, hook: hook)
    expect(service).to have_received(:perform)
  end

  it 'does nothing when Slack is not connected' do
    described_class.perform_now(monitor.id, conversation.id)

    expect(ConversationMonitors::SlackAlertService).not_to have_received(:new)
  end

  it 'does nothing when the monitor is paused or has no channel' do
    create(:integrations_hook, account: account)
    monitor.update!(paused_at: Time.current)
    described_class.perform_now(monitor.id, conversation.id)

    monitor.update!(paused_at: nil, slack_channel_id: nil)
    described_class.perform_now(monitor.id, conversation.id)

    expect(ConversationMonitors::SlackAlertService).not_to have_received(:new)
  end
end
