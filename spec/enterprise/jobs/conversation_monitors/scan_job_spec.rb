require 'rails_helper'

RSpec.describe ConversationMonitors::ScanJob do
  let(:account) { create(:account) }
  let(:monitor) { create(:conversation_monitor, account: account) }
  let(:conversation) { create(:conversation, account: account, created_at: 2.days.ago) }

  before { account.enable_features!('reports', 'conversation_monitors') }

  it 'enumerates only the initial seven-day population in the owning account' do
    conversation
    create(:conversation, account: account, created_at: 8.days.ago)
    create(:conversation, created_at: 2.days.ago)
    monitor
    create(:conversation, account: account, created_at: 1.minute.from_now)

    described_class.perform_now(monitor.initial_scan.id)

    expect(monitor.evaluations.pluck(:conversation_id)).to eq([conversation.id])
    expect(monitor.initial_scan.reload.enumerated_at).to be_present
    expect(ConversationMonitors::WorkItem.find_by!(conversation_id: conversation.id).due_at).to be_present
  end

  it 'resumes a bounded scan and tolerates duplicate jobs without duplicate memberships' do
    conversations = create_list(:conversation, 3, account: account, created_at: 2.days.ago)
    stub_const('ConversationMonitors::ScanJob::BATCH_SIZE', 2)

    described_class.perform_now(monitor.initial_scan.id)
    expect(monitor.initial_scan.reload.enumerated_at).to be_nil
    expect(monitor.evaluations.count).to eq(2)
    described_class.perform_now(monitor.initial_scan.id)
    described_class.perform_now(monitor.initial_scan.id)

    expect(monitor.evaluations.pluck(:conversation_id)).to match_array(conversations.map(&:id))
    expect(monitor.initial_scan.reload.enumerated_at).to be_present
  end

  it 'recovers durable work after enqueue fails after a batch commits' do
    conversation
    failing_enqueue = instance_double(ActiveJob::ConfiguredJob)
    allow(ConversationMonitors::ProcessJob).to receive(:set).and_return(failing_enqueue)
    allow(failing_enqueue).to receive(:perform_later).and_raise(Redis::CannotConnectError)

    expect { described_class.perform_now(monitor.initial_scan.id) }.to raise_error(Redis::CannotConnectError)
    work = ConversationMonitors::WorkItem.find_by!(conversation_id: conversation.id)
    expect(monitor.evaluations.pluck(:conversation_id)).to eq([conversation.id])
    work.update!(due_at: 1.second.ago)

    expect { ConversationMonitors::DispatchJob.perform_now }.to have_enqueued_job(ConversationMonitors::ProcessJob).with(conversation.id)
  end

  it 'retains the unfinished cursor while collection is disabled' do
    conversation
    monitor
    account.disable_features!('conversation_monitors')

    described_class.perform_now(monitor.initial_scan.id)

    expect(monitor.initial_scan.reload.cursor).to eq(0)
    expect(monitor.initial_scan.enumerated_at).to be_nil
    expect(monitor.evaluations).not_to exist
  end

  it 'does not restart paused history through queued backfill, retry, or recovery jobs' do
    conversation
    monitor.update!(paused_at: Time.current)
    clear_enqueued_jobs

    described_class.perform_now(monitor.initial_scan.id)
    ConversationMonitors::RetryJob.perform_now(monitor.id)
    ConversationMonitors::DispatchJob.perform_now

    expect(monitor.initial_scan.reload.cursor).to eq(0)
    expect(monitor.evaluations).not_to exist
    expect(described_class).not_to have_been_enqueued
    expect(ConversationMonitors::ProcessJob).not_to have_been_enqueued
  end
end
