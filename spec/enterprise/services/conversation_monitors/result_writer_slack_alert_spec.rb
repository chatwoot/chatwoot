require 'rails_helper'

RSpec.describe ConversationMonitors::ResultWriter do
  let(:account) { create(:account) }
  let(:monitor) { create(:conversation_monitor, account: account, slack_channel_id: 'C0ALERTS') }
  let(:conversation) { create(:conversation, account: account) }
  let(:work) { ConversationMonitors::WorkItem.find_by!(conversation_id: conversation.id) }
  let(:snapshot) do
    { token: 'claim', generation: work.generation, revision: work.revision,
      monitor_versions: { monitor.id => monitor.collection_version }, live_activity_at: work.live_activity_at }
  end

  before do
    account.enable_features!('automations', 'reports', 'conversation_monitors')
    monitor
    create(:message, account: account, conversation: conversation, content: 'Refund please')
    work.update!(lease_token: 'claim')
  end

  it 'queues one Slack alert for the first live match' do
    writer = described_class.new(work, snapshot)

    expect { writer.write(monitor, score: 0.9) }
      .to have_enqueued_job(ConversationMonitors::SlackAlertJob).with(monitor.id, conversation.id).once

    monitor.evaluations.sole.update!(status: 'pending', matched_at: nil)
    expect { writer.write(monitor, score: 0.9) }.not_to have_enqueued_job(ConversationMonitors::SlackAlertJob)
  end

  it 'does not alert for historical matches' do
    writer = described_class.new(work, snapshot.merge(live_activity_at: nil))

    expect { writer.write(monitor, score: 0.9) }.not_to have_enqueued_job(ConversationMonitors::SlackAlertJob)
  end

  it 'does not alert when the monitor has no Slack channel' do
    monitor.update!(slack_channel_id: nil)

    expect { described_class.new(work, snapshot).write(monitor, score: 0.9) }.not_to have_enqueued_job(ConversationMonitors::SlackAlertJob)
  end

  it 'does not alert when the conversation does not match' do
    expect { described_class.new(work, snapshot).write(monitor, score: 0.1) }.not_to have_enqueued_job(ConversationMonitors::SlackAlertJob)
  end
end
