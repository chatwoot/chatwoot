require 'rails_helper'

RSpec.describe ConversationMonitors::RetryJob do
  let(:account) { create(:account) }
  let(:monitor) { create(:conversation_monitor, account: account, recheck_requested_at: Time.current) }
  let(:conversation) { create(:conversation, account: account) }

  before do
    account.enable_features!('reports', 'conversation_monitors')
    monitor.evaluations.create!(account: account, conversation: conversation, status: 'pending')
  end

  it 'ignores a duplicate queued recheck after the claimed run completes' do
    requested_at = monitor.recheck_requested_at
    described_class.perform_now(monitor.id, requested_at)
    work = ConversationMonitors::WorkItem.find_by!(conversation: conversation)
    revision = work.revision

    described_class.perform_now(monitor.id, requested_at)

    expect(work.reload.revision).to eq(revision)
    expect(monitor.reload.recheck_requested_at).to be_nil
  end

  it 'does not schedule work while another worker holds the monitor recheck lock' do
    lock_id = described_class::LOCK_BASE + monitor.id
    connection_info = ApplicationRecord.connection.raw_connection.conninfo_hash.reject { |_key, value| value.blank? }
    other_connection = PG.connect(connection_info)
    other_connection.exec("SELECT pg_advisory_lock(#{lock_id})")

    expect { described_class.perform_now(monitor.id, monitor.recheck_requested_at) }.not_to change(ConversationMonitors::WorkItem, :count)
    expect(monitor.reload.recheck_requested_at).to be_present
  ensure
    other_connection&.exec("SELECT pg_advisory_unlock(#{lock_id})")
    other_connection&.close
  end
end
