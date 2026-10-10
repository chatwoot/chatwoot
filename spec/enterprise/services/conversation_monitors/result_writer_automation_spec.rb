require 'rails_helper'

RSpec.describe ConversationMonitors::ResultWriter do
  let(:account) { create(:account) }
  let(:monitor) { create(:conversation_monitor, account: account) }
  let(:conversation) { create(:conversation, account: account) }
  let(:work) { ConversationMonitors::WorkItem.find_by!(conversation_id: conversation.id) }
  let(:rule) do
    create(:automation_rule, account: account, event_name: 'monitor_matched', monitor: monitor,
                             conditions: [], actions: [{ action_name: 'add_label', action_params: ['refund'] }])
  end

  before do
    account.enable_features!('automations', 'reports', 'conversation_monitors')
    monitor
    rule
    create(:message, account: account, conversation: conversation, content: 'Refund please')
    work.update!(lease_token: 'claim')
  end

  it 'records one delivery for the first live match and never replays it after re-evaluation' do
    snapshot = { token: 'claim', generation: work.generation, revision: work.revision,
                 monitor_versions: { monitor.id => monitor.collection_version }, live_activity_at: work.live_activity_at }
    writer = described_class.new(work, snapshot)

    writer.write(monitor, score: 0.9)
    expect(monitor.evaluations.sole.first_matched_at).to be_present
    expect(monitor.automation_deliveries.sole.automation_rule).to eq(rule)

    monitor.evaluations.sole.update!(status: 'pending', matched_at: nil)
    writer.write(monitor, score: 0.9)
    expect(monitor.automation_deliveries.count).to eq(1)
  end

  it 'records a historical first match without dispatching an automation' do
    snapshot = { token: 'claim', generation: work.generation, revision: work.revision,
                 monitor_versions: { monitor.id => monitor.collection_version }, live_activity_at: nil }

    described_class.new(work, snapshot).write(monitor, score: 0.9)

    expect(monitor.evaluations.sole.first_matched_at).to be_present
    expect(monitor.automation_deliveries).to be_empty
  end
end
