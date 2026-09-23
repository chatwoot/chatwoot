require 'rails_helper'

RSpec.describe ConversationMonitors::Resume do
  let(:account) { create(:account) }
  let(:monitor) { create(:conversation_monitor, account: account, paused_at: 2.hours.ago, created_at: 3.days.ago) }
  let(:conversation) { create(:conversation, account: account, created_at: 1.day.ago) }
  let(:endpoint) { ConversationMonitors::Configuration.endpoint }

  before do
    create(:installation_config, name: 'CAPTAIN_OPENROUTER_API_KEY', value: 'test-key')
    account.enable_features!('reports', 'conversation_monitors')
    stub_request(:post, endpoint).to_return do |request|
      answers = JSON.parse(request.body)['questions'].keys.index_with { { type: 'noul', noul: 0.95 } }
      { status: 200, body: { model: 'typesafe/jev-1.13-20260917', answers: answers, usage: { input_tokens: 100 } }.to_json }
    end
  end

  it 'starts from now without evaluating old queued activity, then handles a new message' do
    monitor.evaluations.create!(account: account, conversation: conversation, status: 'pending')
    work = ConversationMonitors::WorkItem.create!(account: account, conversation: conversation, activity_at: 1.hour.ago,
                                                  requested_at: 1.hour.ago, due_at: Time.current, revision: 1)
    described_class.new(monitor, mode: 'from_now', collection_version: 0).perform
    ConversationMonitors::Evaluator.new(work.reload).perform

    expect(WebMock).not_to have_requested(:post, endpoint)
    expect(monitor.evaluations.sole.status).to eq('skipped')
    expect(monitor.initial_scan.reload.cancelled_at).to be_present
    create(:message, account: account, conversation: conversation, content: 'A refund after resuming')
    work.reload.update!(due_at: Time.current)
    ConversationMonitors::Evaluator.new(work).perform

    expect(monitor.evaluations.sole.status).to eq('matched')
    expect(WebMock).to have_requested(:post, endpoint).once
  end

  it 'catches up new conversations and public replies on older conversations, excluding private notes' do
    monitor
    fresh = create(:conversation, account: account, created_at: 1.hour.ago)
    private_only = create(:conversation, account: account, created_at: 1.day.ago)
    agent_only = create(:conversation, account: account, created_at: 1.day.ago)
    [conversation, fresh].each { |entry| create(:message, account: account, conversation: entry, content: 'Refund', created_at: 1.hour.ago) }
    create(:message, :outgoing, account: account, conversation: private_only, private: true, content: 'Refund', created_at: 1.hour.ago)
    create(:message, :outgoing, account: account, conversation: agent_only, content: 'Refund', created_at: 1.hour.ago)

    described_class.new(monitor, mode: 'catch_up', collection_version: 0).perform
    resumption = monitor.scans.where.not(kind: 'initial').sole
    ConversationMonitors::ScanJob.perform_now(resumption.id)
    expect(monitor.evaluations.pluck(:conversation_id)).to contain_exactly(conversation.id, fresh.id, agent_only.id)
    ConversationMonitors::WorkItem.where(account: account).each do |work|
      work.update!(due_at: Time.current)
      ConversationMonitors::Evaluator.new(work).perform
    end
    ConversationMonitors::ScanJob.perform_now(resumption.id)

    expect(resumption.reload.enumerated_at).to be_present
    expect(monitor.matched_conversations.pluck(:id)).to contain_exactly(conversation.id, fresh.id, agent_only.id)
    expect(WebMock).to have_requested(:post, endpoint).times(3)
  end

  it 'does not catch up a future-only monitor when another monitor queues the same conversation' do
    other = create(:conversation_monitor, account: account, paused_at: 2.hours.ago)
    monitor
    create(:message, account: account, conversation: conversation, content: 'Refund during pause', created_at: 1.hour.ago)
    described_class.new(monitor, mode: 'from_now', collection_version: 0).perform
    described_class.new(other, mode: 'catch_up', collection_version: 0).perform
    ConversationMonitors::ScanJob.perform_now(other.scans.where.not(kind: 'initial').sole.id)
    work = ConversationMonitors::WorkItem.find_by!(conversation: conversation)
    work.update!(due_at: Time.current)
    ConversationMonitors::Evaluator.new(work).perform

    expect(monitor.evaluations).not_to exist
    expect(other.evaluations.sole.status).to eq('matched')
    expect(WebMock).to have_requested(:post, endpoint).with { |request| JSON.parse(request.body)['questions'].keys == [other.id.to_s] }.once
  end

  it 'preserves prior matches and does not reclassify them during catch-up' do
    monitor.evaluations.create!(account: account, conversation: conversation, status: 'matched')
    create(:message, account: account, conversation: conversation, content: 'Another refund request', created_at: 1.hour.ago)
    described_class.new(monitor, mode: 'catch_up', collection_version: 0).perform
    ConversationMonitors::ScanJob.perform_now(monitor.scans.where.not(kind: 'initial').sole.id)
    ConversationMonitors::WorkItem.where(account: account).each { |work| ConversationMonitors::Evaluator.new(work).perform }

    expect(monitor.matched_conversations.pluck(:id)).to eq([conversation.id])
    expect(WebMock).not_to have_requested(:post, endpoint)
  end

  it 'recovers catch-up scans if the initial enqueue fails' do
    allow(ConversationMonitors::ScanJob).to receive(:perform_later).and_raise(Redis::CannotConnectError)
    described_class.new(monitor, mode: 'catch_up', collection_version: 0).perform
    resumption = monitor.scans.where.not(kind: 'initial').sole
    allow(ConversationMonitors::ScanJob).to receive(:perform_later).and_call_original

    expect(monitor.reload.paused_at).to be_nil
    expect { ConversationMonitors::DispatchJob.perform_now }.to have_enqueued_job(ConversationMonitors::ScanJob).with(resumption.id)
  end

  it 'does not let stale resume requests restart a later pause' do
    described_class.new(monitor, mode: 'from_now', collection_version: 0).perform
    monitor.update!(paused_at: Time.current, collection_version: monitor.collection_version + 1)

    expect do
      described_class.new(monitor, mode: 'catch_up', collection_version: 0).perform
    end.to raise_error(CustomExceptions::MonitorParametersError, 'monitor_changed')
    expect(monitor.reload.paused_at).to be_present
    expect(monitor.scans.where.not(kind: 'initial').count).to eq(1)
  end

  it 'enforces the active-monitor limit when resuming' do
    create(:conversation_monitor, account: account)
    with_modified_env(CONVERSATION_MONITORS_LIMIT: '1') do
      expect do
        described_class.new(monitor, mode: 'from_now', collection_version: 0).perform
      end.to raise_error(CustomExceptions::MonitorParametersError, 'monitor_limit')
    end
    expect(monitor.reload.paused_at).to be_present
  end

  it 'does not revive a previous catch-up after another pause and future-only resume' do
    monitor
    create(:message, account: account, conversation: conversation, content: 'Refund', created_at: 1.hour.ago)
    described_class.new(monitor, mode: 'catch_up', collection_version: 0).perform
    resumption = monitor.scans.where.not(kind: 'initial').sole
    monitor.update!(paused_at: Time.current, collection_version: monitor.collection_version + 1)
    ConversationMonitors::ScanJob.perform_now(resumption.id)
    expect(monitor.evaluations).not_to exist
    described_class.new(monitor, mode: 'from_now', collection_version: monitor.collection_version).perform
    ConversationMonitors::ScanJob.perform_now(resumption.id)

    expect(resumption.reload.cancelled_at).to be_present
    expect(monitor.evaluations).not_to exist
  end

  it 'does not accept an old in-flight result after a pause and resume cycle' do
    monitor.update!(paused_at: nil)
    create(:message, account: account, conversation: conversation, content: 'Refund')
    work = ConversationMonitors::WorkItem.find_by!(conversation: conversation)
    work.update!(due_at: Time.current)
    stub_request(:post, endpoint).to_return do
      monitor.update!(paused_at: Time.current, collection_version: 1)
      described_class.new(monitor, mode: 'from_now', collection_version: 1).perform
      { status: 200,
        body: { model: 'typesafe/jev-1.13-20260917', answers: { monitor.id.to_s => { type: 'noul', noul: 0.99 } },
                usage: { input_tokens: 10 } }.to_json }
    end
    ConversationMonitors::Evaluator.new(work).perform

    expect(monitor.evaluations).not_to exist
    expect(monitor.reload.collection_version).to eq(2)
  end

  it 'catches up a paused-period message that commits after enumeration has finished' do
    monitor
    conversation
    described_class.new(monitor, mode: 'catch_up', collection_version: 0).perform
    ConversationMonitors::ScanJob.perform_now(monitor.scans.where.not(kind: 'initial').sole.id)
    create(:message, account: account, conversation: conversation, content: 'Late committed refund', created_at: 1.hour.ago)
    work = ConversationMonitors::WorkItem.find_by!(conversation: conversation)
    work.update!(due_at: Time.current)
    ConversationMonitors::Evaluator.new(work).perform

    expect(monitor.evaluations.sole.status).to eq('matched')
  end

  it 'leaves skipped paused periods visibly incomplete in charts and progress' do
    monitor.initial_scan.update!(enumerated_at: Time.current)
    described_class.new(monitor, mode: 'from_now', collection_version: 0).perform
    report = ConversationMonitors::Report.new(monitor, { since: 3.hours.ago.to_i, until: 1.minute.from_now.to_i, interval: 'hour', timezone: 'UTC' })
    processing = ConversationMonitors::Presenter.new(monitor).as_json[:processing]

    expect(report.timeseries[:buckets].count { |bucket| !bucket[:covered] }).to be_positive
    expect(processing[:state]).to eq('live')
  end

  it 'keeps canceled initial history visibly incomplete after the pause-period catch-up finishes' do
    monitor
    historical = create(:conversation, account: account, created_at: 4.days.ago)
    described_class.new(monitor, mode: 'catch_up', collection_version: 0).perform
    scan = monitor.scans.find_by!(kind: 'catch_up')
    ConversationMonitors::ScanJob.perform_now(scan.id)
    report = ConversationMonitors::Report.new(monitor, { since: 5.days.ago.to_i, until: 3.days.ago.to_i, interval: 'day', timezone: 'UTC' })

    expect(scan.reload.enumerated_at).to be_present
    expect(monitor.initial_scan.cancelled_at).to be_present
    expect(monitor.initial_scan.population).to include(historical)
    expect(monitor.evaluations).not_to exist
    expect(report.timeseries[:buckets]).to all(include(covered: false))
  end

  it 'marks older conversation buckets incomplete when their pause-period activity was skipped' do
    monitor.initial_scan.update!(enumerated_at: Time.current)
    described_class.new(monitor, mode: 'from_now', collection_version: 0).perform
    report = ConversationMonitors::Report.new(monitor, { since: 2.days.ago.to_i, until: 1.day.ago.to_i, interval: 'day', timezone: 'UTC' })

    expect(report.timeseries[:buckets]).to all(include(covered: false))
  end

  it 'does not advance a catch-up cursor past conversations skipped by a concurrent pause' do
    monitor
    create(:message, account: account, conversation: conversation, created_at: 1.hour.ago)
    described_class.new(monitor, mode: 'catch_up', collection_version: 0).perform
    resumption = monitor.scans.where.not(kind: 'initial').sole
    allow(ConversationMonitors::Scheduler).to receive(:request_for_monitor).and_wrap_original do |original, *args|
      monitor.update!(paused_at: Time.current, collection_version: monitor.collection_version + 1)
      original.call(*args)
    end
    ConversationMonitors::ScanJob.perform_now(resumption.id)

    expect(resumption.reload.cursor).to eq(0)
    expect(resumption.enumerated_at).to be_nil
    expect(monitor.evaluations).not_to exist
  end

  it 'marks an enumerated but unfinished earlier catch-up as incomplete on the next resume' do
    monitor
    create(:message, account: account, conversation: conversation, created_at: 1.hour.ago)
    described_class.new(monitor, mode: 'catch_up', collection_version: 0).perform
    resumption = monitor.scans.where.not(kind: 'initial').sole
    ConversationMonitors::ScanJob.perform_now(resumption.id)
    monitor.update!(paused_at: Time.current, collection_version: monitor.collection_version + 1)
    described_class.new(monitor, mode: 'catch_up', collection_version: monitor.collection_version).perform

    expect(resumption.reload.cancelled_at).to be_present
    expect(monitor.evaluations.sole.status).to eq('skipped')
    report = ConversationMonitors::Report.new(monitor, { since: 3.hours.ago.to_i, until: Time.current.to_i, interval: 'hour', timezone: 'UTC' })
    expect(report.timeseries[:buckets].any? { |bucket| !bucket[:covered] }).to be(true)
  end
end
