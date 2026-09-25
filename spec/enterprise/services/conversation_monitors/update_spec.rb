require 'rails_helper'

RSpec.describe ConversationMonitors::Update do
  let(:account) { create(:account) }
  let(:monitor) { create(:conversation_monitor, account: account) }
  let(:conversation) { create(:conversation, account: account, created_at: 2.days.ago) }
  let(:endpoint) { ConversationMonitors::Configuration.endpoint }

  before do
    create(:installation_config, name: 'CAPTAIN_OPENROUTER_API_KEY', value: 'test-key')
    account.enable_features!('reports', 'conversation_monitors')
  end

  it 'clears old decisions and rechecks monitored conversations without changing another monitor or skipped history' do
    skipped = create(:conversation, account: account)
    other = create(:conversation_monitor, account: account)
    monitor.evaluations.create!(account: account, conversation: conversation, status: 'matched', score: 0.9)
    monitor.evaluations.create!(account: account, conversation: skipped, status: 'skipped')
    other.evaluations.create!(account: account, conversation: conversation, status: 'matched')
    create(:message, account: account, conversation: conversation, content: 'Refund')
    stub_request(:post, endpoint).to_return(status: 200, body: {
      model: 'typesafe/jev-1.13-20260917', answers: { monitor.id.to_s => { type: 'noul', noul: 0.1 } }, usage: { input_tokens: 10 }
    }.to_json)

    described_class.new(monitor, { 'condition' => 'Questions about shipping' }, collection_version: 0).perform

    expect(monitor.matched_conversations).not_to exist
    expect(monitor.evaluations.find_by!(conversation: conversation).score).to be_nil
    expect(monitor.recheck_requested_at).to be_present
    ConversationMonitors::RetryJob.perform_now(monitor.id)
    work = ConversationMonitors::WorkItem.find_by!(conversation: conversation)
    work.update!(due_at: Time.current)
    ConversationMonitors::Evaluator.new(work).perform

    expect(monitor.evaluations.find_by!(conversation: conversation).status).to eq('unmatched')
    expect(monitor.evaluations.find_by!(conversation: skipped).status).to eq('skipped')
    expect(other.evaluations.sole.status).to eq('matched')
    expect(monitor.reload.recheck_requested_at).to be_nil
  end

  it 'does not reset results or queue a recheck when only the name changes' do
    monitor.evaluations.create!(account: account, conversation: conversation, status: 'matched')
    expect do
      described_class.new(monitor, { 'name' => 'New name', 'condition' => monitor.condition }, collection_version: 0).perform
    end.not_to have_enqueued_job(ConversationMonitors::RetryJob)

    expect(monitor.reload.name).to eq('New name')
    expect(monitor.collection_version).to eq(0)
    expect(monitor.evaluations.sole.status).to eq('matched')
  end

  it 'defers a paused recheck until resuming from now without discarding the requested recheck' do
    monitor.update!(paused_at: 1.hour.ago)
    monitor.evaluations.create!(account: account, conversation: conversation, status: 'matched')
    described_class.new(monitor, { 'condition' => 'Shipping questions' }, collection_version: 0).perform
    ConversationMonitors::RetryJob.perform_now(monitor.id)
    expect(monitor.reload.recheck_requested_at).to be_present
    expect(ConversationMonitors::WorkItem.find_by(conversation: conversation)&.due_at).to be_nil

    ConversationMonitors::Resume.new(monitor, mode: 'from_now', collection_version: 1).perform
    ConversationMonitors::RetryJob.perform_now(monitor.id)

    expect(monitor.evaluations.sole.status).to eq('pending')
    expect(monitor.evaluations.sole.requested_version).to eq(2)
    expect(ConversationMonitors::WorkItem.find_by!(conversation: conversation).due_at).to be_present
    expect(monitor.reload.recheck_requested_at).to be_nil
  end

  it 'keeps a running catch-up scan eligible under the new definition' do
    monitor.update!(paused_at: 2.hours.ago)
    ConversationMonitors::Resume.new(monitor, mode: 'catch_up', collection_version: 0).perform
    resumption = monitor.scans.where.not(kind: 'initial').sole
    create(:message, account: account, conversation: conversation, created_at: 1.hour.ago)

    described_class.new(monitor, { 'condition' => 'Shipping questions' }, collection_version: 1).perform
    ConversationMonitors::ScanJob.perform_now(resumption.id)

    expect(resumption.reload.collection_version).to eq(2)
    expect(resumption.enumerated_at).to be_present
    expect(monitor.evaluations.sole.requested_version).to eq(2)
  end

  it 'rejects in-flight results evaluated using the previous description' do
    monitor
    create(:message, account: account, conversation: conversation, content: 'Refund')
    work = ConversationMonitors::WorkItem.find_by!(conversation: conversation)
    work.update!(due_at: Time.current)
    stub_request(:post, endpoint).to_return do
      described_class.new(monitor, { 'condition' => 'Shipping questions' }, collection_version: 0).perform
      { status: 200, body: {
        model: 'typesafe/jev-1.13-20260917', answers: { monitor.id.to_s => { type: 'noul', noul: 0.99 } }, usage: { input_tokens: 10 }
      }.to_json }
    end
    ConversationMonitors::Evaluator.new(work).perform

    expect(monitor.matched_conversations).not_to exist
    expect(monitor.reload.condition).to eq('Shipping questions')
    expect(work.reload.due_at).to be_present
    stub_request(:post, endpoint).to_return(status: 200, body: {
      model: 'typesafe/jev-1.13-20260917', answers: { monitor.id.to_s => { type: 'noul', noul: 0.1 } }, usage: { input_tokens: 10 }
    }.to_json)
    work.update!(due_at: Time.current)
    ConversationMonitors::Evaluator.new(work).perform
    expect(monitor.evaluations.sole.status).to eq('unmatched')
  end

  it 'recovers a recheck after the initial enqueue fails' do
    monitor.evaluations.create!(account: account, conversation: conversation, status: 'matched')
    allow(ConversationMonitors::RetryJob).to receive(:perform_later).and_raise(Redis::CannotConnectError)
    described_class.new(monitor, { 'condition' => 'Shipping questions' }, collection_version: 0).perform
    allow(ConversationMonitors::RetryJob).to receive(:perform_later).and_call_original

    expect { ConversationMonitors::DispatchJob.perform_now }.to have_enqueued_job(ConversationMonitors::RetryJob).with(
      monitor.id, monitor.reload.recheck_requested_at
    )
  end
end
