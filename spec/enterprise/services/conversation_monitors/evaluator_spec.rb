require 'rails_helper'

RSpec.describe ConversationMonitors::Evaluator do
  subject(:evaluate) { -> { described_class.new(work.reload).perform } }

  let(:account) { create(:account) }
  let(:monitor) { create(:conversation_monitor, account: account) }
  let(:second) { create(:conversation_monitor, account: account, condition: 'Mentions WhatsApp BSUID') }
  let(:conversation) { create(:conversation, account: account) }
  let(:message) { create(:message, account: account, conversation: conversation, content: 'Please refund my order') }
  let(:work) { ConversationMonitors::WorkItem.find_by!(conversation_id: conversation.id) }
  let(:answers) { { monitor.id.to_s => { type: 'noul', noul: 0.95 }, second.id.to_s => { type: 'noul', noul: 0.05 } } }
  let(:response_body) { { model: 'typesafe/jev-1.13-20260917', answers: answers, usage: { input_tokens: 100 } } }
  let(:endpoint) { ConversationMonitors::Configuration.endpoint }

  before do
    create(:installation_config, name: 'CAPTAIN_OPENROUTER_API_KEY', value: 'test-key')
    account.enable_features!('reports', 'conversation_monitors')
    monitor
    second
    message
    work.update!(due_at: Time.current)
    stub_request(:post, endpoint).to_return(status: 200, body: response_body.to_json)
  end

  it 'batches independent questions and counts a conversation only once per monitor' do
    boundary_answers = { monitor.id.to_s => { type: 'noul', noul: 0.6 }, second.id.to_s => { type: 'noul', noul: 0.5999 } }
    stub_request(:post, endpoint).to_return(status: 200, body: response_body.merge(answers: boundary_answers).to_json)
    evaluate.call
    expect(monitor.evaluations.sole.status).to eq('matched')
    expect(second.evaluations.sole.status).to eq('unmatched')
    work.update!(due_at: Time.current)
    evaluate.call

    expect(monitor.evaluations.count).to eq(1)
    expect(WebMock).to have_requested(:post, endpoint).once
    expect(work.reload.due_at).to be_nil
    expect(ConversationMonitors::DailyUsage.find_by!(account: account).calls_count).to eq(1)
  end

  it 'persists successful answers without another provider call when Redis reconciliation fails' do
    redis = Redis::Alfred.with { |connection| connection }
    allow(redis).to receive(:incrby).and_raise(Redis::CannotConnectError, 'test outage')

    evaluate.call

    expect(monitor.evaluations.sole).to have_attributes(status: 'matched', score: 0.95)
    expect(second.evaluations.sole).to have_attributes(status: 'unmatched', score: 0.05)
    expect(work.reload).to have_attributes(due_at: nil, lease_token: nil, lease_expires_at: nil, processed_revision: work.revision)

    travel 3.minutes
    expect { ConversationMonitors::DispatchJob.perform_now }.not_to have_enqueued_job(ConversationMonitors::ProcessJob)
    ConversationMonitors::ProcessJob.perform_now(conversation.id)

    expect(WebMock).to have_requested(:post, endpoint).once
    expect(ConversationMonitors::DailyUsage.find_by!(account: account).calls_count).to eq(1)
  end

  context 'when a monitor uses a legacy model alias' do
    let(:monitor) { create(:conversation_monitor, account: account, model: 'jev-1.13.0') }

    it 'shares one provider request and credit with the canonical model without changing stored model names' do
      evaluate.call

      expect(WebMock).to have_requested(:post, endpoint).with { |request|
        body = JSON.parse(request.body)
        body['model'] == 'typesafe/jev-1.13' && body['questions'].keys.sort == [monitor.id.to_s, second.id.to_s].sort
      }.once
      expect(WebMock).to have_requested(:post, endpoint).once
      expect(ConversationMonitors::Usage.new(account.id).snapshot[:used]).to eq(1)
      expect(monitor.reload.model).to eq('jev-1.13.0')
      expect(second.reload.model).to eq('typesafe/jev-1.13')
      expect(monitor.evaluations.sole.status).to eq('matched')
      expect(second.evaluations.sole.status).to eq('unmatched')
    end

    it 'keeps a different provider model in a separate request' do
      other = create(:conversation_monitor, account: account, model: 'other/provider-model', created_at: 1.minute.ago)
      batches = {}
      stub_request(:post, endpoint).to_return do |request|
        body = JSON.parse(request.body)
        batches[body['model']] = body['questions'].keys
        values = body['questions'].keys.index_with { { type: 'noul', noul: 0.9 } }
        { status: 200, body: response_body.merge(model: body['model'], answers: values).to_json }
      end

      evaluate.call

      expect(batches.keys).to contain_exactly('typesafe/jev-1.13', 'other/provider-model')
      expect(batches['typesafe/jev-1.13']).to contain_exactly(monitor.id.to_s, second.id.to_s)
      expect(batches['other/provider-model']).to eq([other.id.to_s])
      expect(WebMock).to have_requested(:post, endpoint).twice
      expect(ConversationMonitors::Usage.new(account.id).snapshot[:used]).to eq(2)
      expect(other.evaluations.sole).to have_attributes(status: 'matched', model: 'other/provider-model')
    end
  end

  { 20 => [20], 21 => [20, 1] }.each do |count, batch_sizes|
    it "evaluates #{count} conditions in batches of #{batch_sizes.join(' and ')} with one credit per call" do
      monitors = [monitor, second] + create_list(:conversation_monitor, count - 2, account: account, created_at: 1.minute.ago)
      batches = []
      stub_request(:post, endpoint).to_return do |request|
        questions = JSON.parse(request.body)['questions']
        batches << questions.keys
        values = questions.keys.index_with { { type: 'noul', noul: 0.9 } }
        { status: 200, body: response_body.merge(answers: values).to_json }
      end

      evaluate.call

      expect(batches.map(&:size)).to eq(batch_sizes)
      expect(batches.flatten).to match_array(monitors.map { |entry| entry.id.to_s })
      expect(ConversationMonitors::Evaluation.where(conversation: conversation, status: 'matched').count).to eq(count)
      expect(ConversationMonitors::Usage.new(account.id).snapshot[:used]).to eq(batch_sizes.size)
      expect(work.reload.due_at).to be_nil
    end
  end

  { 'Refunds ' * 250 => 2, '退款' * 1000 => 4 }.each do |condition, calls|
    it "splits oversized batches into #{calls} calls without charging for local checks or losing conditions" do
      monitor.update!(condition: condition)
      second.update!(condition: condition)
      monitors = [monitor, second] + create_list(:conversation_monitor, 18, account: account, condition: condition)
      create(:message, account: account, conversation: conversation, content: 'x' * 30_000)
      work.reload.update!(due_at: Time.current)
      batches = []
      payload_sizes = []
      stub_request(:post, endpoint).to_return do |request|
        questions = JSON.parse(request.body)['questions']
        batches << questions.keys
        payload_sizes << request.body.bytesize
        values = questions.keys.index_with { { type: 'noul', noul: 0.9 } }
        { status: 200, body: response_body.merge(answers: values).to_json }
      end

      evaluate.call

      expect(batches.size).to eq(calls)
      expect(payload_sizes).to all(be <= ConversationMonitors::Configuration::MAX_REQUEST_BYTES)
      expect(batches.flatten).to match_array(monitors.map { |entry| entry.id.to_s })
      expect(ConversationMonitors::Evaluation.where(conversation: conversation, status: 'matched').count).to eq(20)
      expect(ConversationMonitors::Usage.new(account.id).snapshot[:used]).to eq(calls)
      expect(work.reload.due_at).to be_nil
    end
  end

  it 'holds exhausted accounts until next month and preserves full history across new input' do
    now = Time.current.utc
    ConversationMonitors::DailyUsage.create!(account: account, usage_date: now.to_date, calls_count: 100_000, limit_reached_at: now)
    work.update!(attempts: 10)

    evaluate.call

    expect(WebMock).not_to have_requested(:post, endpoint)
    expect(work.reload).to have_attributes(error_code: 'monthly_limit', due_at: be_within(2.seconds).of(now.beginning_of_month.next_month),
                                           full_history_revision: be > work.processed_revision)
    expect(monitor.evaluations.sole.error_code).to eq('monthly_limit')
    due_at = work.due_at
    create(:message, account: account, conversation: conversation, content: 'Another message during the quota hold')
    expect(work.reload).to have_attributes(due_at: due_at, error_code: 'monthly_limit')

    travel_to(now.beginning_of_month.next_month + 3.seconds) do
      evaluate.call
      expect(WebMock).to have_requested(:post, endpoint).once
      expect(monitor.evaluations.sole.status).to eq('matched')
      expect(ConversationMonitors::Usage.new(account.id).snapshot[:used]).to eq(1)
    end
  end

  it 'prioritizes the monthly hold when an earlier batch failed using the final credit' do
    now = Time.current.utc
    ConversationMonitors::DailyUsage.create!(account: account, usage_date: now.to_date, calls_count: 99_999)
    create_list(:conversation_monitor, 19, account: account, created_at: 1.minute.ago)
    stub_request(:post, endpoint).to_return(status: 429)

    evaluate.call

    expect(WebMock).to have_requested(:post, endpoint).once
    expect(work.reload).to have_attributes(error_code: 'monthly_limit', due_at: be_within(2.seconds).of(now.beginning_of_month.next_month),
                                           full_history_revision: be > work.processed_revision)
    expect(ConversationMonitors::Usage.new(account.id).snapshot[:used]).to eq(100_000)
  end

  %i[incoming outgoing].each do |message_type|
    it "reevaluates negatives on new #{message_type} messages without calling already matched conditions" do
      6.times { |index| create(:message, account: account, conversation: conversation, content: "Earlier #{index}") }
      evaluate.call
      create(:message, message_type: message_type, account: account, conversation: conversation, content: 'About WhatsApp BSUID')
      work.reload.update!(due_at: Time.current)
      reply_request = stub_request(:post, endpoint).with do |request|
        body = JSON.parse(request.body)
        speaker = message_type == :incoming ? 'customer' : 'agent'
        body['questions'].keys == [second.id.to_s] &&
          body['state']['messages'].pluck('text') == ['Earlier 2', 'Earlier 3', 'Earlier 4', 'Earlier 5', 'About WhatsApp BSUID'] &&
          body['state']['messages'].last == { 'speaker' => speaker, 'text' => 'About WhatsApp BSUID' }
      end.to_return(status: 200, body: response_body.deep_merge(answers: { second.id.to_s => { type: 'noul', noul: 0.9 } }).to_json)
      evaluate.call

      expect(second.evaluations.sole.status).to eq('matched')
      expect(monitor.evaluations.sole.status).to eq('matched')
      expect(reply_request).to have_been_requested.once
      expect(WebMock).to have_requested(:post, endpoint).twice
    end
  end

  it 'keeps an input arriving during a provider request due for another evaluation' do
    stub_request(:post, endpoint).to_return do
      create(:message, account: account, conversation: conversation, content: 'Another question')
      ConversationMonitors::Scheduler.request_for_monitor(conversation, second, second.collection_version)
      { status: 200, body: response_body.to_json }
    end
    evaluate.call

    expect(work.reload.revision).to be > work.processed_revision
    expect(work.due_at).to be_present
    expect(work.lease_token).to be_nil
    expect(work.full_history_revision).to be > work.processed_revision
  end

  it 'preserves full-history backfill across live messages and recovery, then returns to the live window' do
    conversation.update!(created_at: 1.day.ago)
    6.times { |index| create(:message, account: account, conversation: conversation, content: "History #{index}") }
    ConversationMonitors::ScanJob.perform_now(monitor.initial_scan.id)
    create(:message, :outgoing, account: account, conversation: conversation, content: 'Reply during backfill')
    work.reload.update!(due_at: Time.current)
    contexts = []
    negative_answers = { monitor.id.to_s => { type: 'noul', noul: 0.1 }, second.id.to_s => { type: 'noul', noul: 0.1 } }
    stub_request(:post, endpoint).to_return do |request|
      contexts << JSON.parse(request.body)['state']['messages'].pluck('text')
      { status: 200, body: response_body.merge(answers: negative_answers).to_json }
    end

    ConversationMonitors::ProcessJob.perform_now(conversation.id)

    expected_history = ['Please refund my order'] + Array.new(6) { |index| "History #{index}" } + ['Reply during backfill']
    expect(contexts.sole).to eq(expected_history)
    expect(work.reload.full_history_revision).to be <= work.processed_revision
    create(:message, account: account, conversation: conversation, content: 'New live message')
    work.reload.update!(due_at: Time.current)
    ConversationMonitors::ProcessJob.perform_now(conversation.id)

    expect(contexts.last).to eq(['History 3', 'History 4', 'History 5', 'Reply during backfill', 'New live message'])
    expect(WebMock).to have_requested(:post, endpoint).twice
  end

  it 'sends trimmed oversized conversations to Jev and saves the returned decisions' do
    create(:message, :outgoing, account: account, conversation: conversation, content: "#{'x' * 30_000} WhatsApp BSUID")
    trimmed_request = stub_request(:post, endpoint).with do |request|
      context = JSON.parse(request.body)['state']
      context['truncated'] && context.to_json.bytesize <= ConversationMonitors::Configuration::MAX_CONTEXT_BYTES &&
        context['messages'].last['text'].end_with?('WhatsApp BSUID')
    end.to_return(status: 200, body: response_body.to_json)

    evaluate.call

    expect(trimmed_request).to have_been_requested.once
    expect(monitor.evaluations.sole.status).to eq('matched')
    expect(second.evaluations.sole.status).to eq('unmatched')
    expect(work.reload.error_code).to be_nil
  end

  it 'rejects an in-flight positive result after redaction' do
    stub_request(:post, endpoint).to_return do
      message.update!(content: 'Deleted', content_attributes: { deleted: true })
      { status: 200, body: response_body.to_json }
    end
    evaluate.call

    expect(monitor.evaluations.where(status: 'matched')).not_to exist
    expect(work.reload.due_at).to be_present
    expect(work.full_history_revision).to be > work.processed_revision
  end

  it 'preserves valid answers while retrying missing answers' do
    stub_request(:post, endpoint).to_return(status: 200, body: response_body.merge(answers: answers.except(second.id.to_s)).to_json)
    evaluate.call

    expect(monitor.evaluations.sole.status).to eq('matched')
    expect(second.evaluations.sole.error_code).to eq('invalid_response')
    expect(work.reload.due_at).to be_present
  end

  it 'honors provider retry-after without recording negatives' do
    stub_request(:post, endpoint).to_return(status: 429, headers: { 'Retry-After' => '120' })
    evaluate.call

    expect(work.reload.due_at).to be >= 119.seconds.from_now
    expect(monitor.evaluations.sole.status).to eq('error')
    expect(monitor.evaluations.sole.error_code).to eq('provider_busy')
    expect(ConversationMonitors::Usage.new(account.id).snapshot[:used]).to eq(1)
  end

  it 'stops after five retryable provider failures' do
    stub_request(:post, endpoint).to_return(status: 429)

    4.times do
      evaluate.call
      expect(work.reload.due_at).to be_present
      travel_to(work.due_at + 1.second)
    end
    evaluate.call

    expect(work.reload).to have_attributes(attempts: 5, due_at: nil)
    expect(WebMock).to have_requested(:post, endpoint).times(5)
    expect(ConversationMonitors::Usage.new(account.id).snapshot[:used]).to eq(5)
  end

  it 'leaves invalid credentials visible without endlessly retrying' do
    stub_request(:post, endpoint).to_return(status: 401)
    evaluate.call

    expect(work.reload.due_at).to be_nil
    expect(monitor.evaluations.sole.error_code).to eq('credentials_invalid')
  end

  it 'recovers missing-key errors through manual retry after the connection is configured' do
    with_modified_env(CAPTAIN_OPENROUTER_API_KEY: nil) do
      config = InstallationConfig.find_by!(name: 'CAPTAIN_OPENROUTER_API_KEY')
      config.update!(value: nil)
      evaluate.call

      expect(monitor.evaluations.sole).to have_attributes(status: 'error', error_code: 'not_configured')
      expect(WebMock).not_to have_requested(:post, endpoint)

      config.update!(value: 'test-key')
      ConversationMonitors::DispatchJob.perform_now
      expect(work.reload.due_at).to be_nil
      ConversationMonitors::RetryJob.perform_now(monitor.id)
      expect(work.reload.due_at).to be_present
      work.update!(due_at: Time.current)
      evaluate.call

      expect(monitor.evaluations.sole).to have_attributes(status: 'matched', error_code: nil)
      expect(WebMock).to have_requested(:post, endpoint).once
      expect(ConversationMonitors::Usage.new(account.id).snapshot[:used]).to eq(1)
    end
  end

  it 'does not evaluate or spend credits when reports access is disabled' do
    account.disable_features!('reports')

    evaluate.call

    expect(WebMock).not_to have_requested(:post, endpoint)
    expect(work.reload.due_at).to be_present
    expect(ConversationMonitors::DailyUsage.where(account: account)).not_to exist
  end

  it 'does not enroll a new monitor into old shared work outside its activation cohort' do
    conversation.update!(created_at: 20.days.ago)
    work.update!(activity_at: 10.days.ago)
    fresh = create(:conversation_monitor, account: account)

    evaluate.call

    expect(fresh.evaluations).not_to exist
    expect(WebMock).not_to have_requested(:post, endpoint)
  end

  it 'includes a monitor activated before message commit even when another monitor already tracked the message' do
    fresh = nil
    public_message = build(:message, account: account, conversation: conversation, content: 'New refund')
    allow(public_message).to receive(:catch_up_monitor_activation).and_wrap_original do |original|
      fresh = create(:conversation_monitor, account: account)
      original.call
    end
    public_message.save!
    work.reload.update!(due_at: Time.current)
    stub_request(:post, endpoint).to_return do |request|
      values = JSON.parse(request.body)['questions'].keys.index_with { { type: 'noul', noul: 0.9 } }
      { status: 200, body: response_body.merge(answers: values).to_json }
    end

    evaluate.call

    expect(fresh.evaluations.sole.status).to eq('matched')
    expect(WebMock).to have_requested(:post, endpoint).once
  end

  it 'preserves due work while collection is disabled' do
    account.disable_features!('conversation_monitors')
    evaluate.call

    expect(WebMock).not_to have_requested(:post, endpoint)
    expect(work.reload.due_at).to be_present
  end

  it 'does not restore a monitor deleted during evaluation' do
    stub_request(:post, endpoint).to_return do
      monitor.update!(deleted_at: Time.current)
      { status: 200, body: response_body.to_json }
    end
    evaluate.call

    expect(monitor.evaluations).not_to exist
    expect(second.evaluations.sole.status).to eq('unmatched')
  end

  it 'does not dispatch more batches after the feature is disabled during a provider call' do
    create_list(:conversation_monitor, 19, account: account, created_at: 1.minute.ago)
    stub_request(:post, endpoint).to_return do |request|
      account.disable_features!('conversation_monitors')
      values = JSON.parse(request.body)['questions'].keys.index_with { |_id| { type: 'noul', noul: 0.9 } }
      { status: 200, body: response_body.merge(answers: values).to_json }
    end
    evaluate.call

    expect(WebMock).to have_requested(:post, endpoint).once
    expect(work.reload.due_at).to be_present
  end

  it 'preserves existing matches and skips future public messages when all monitors are paused' do
    evaluate.call
    monitor.update!(paused_at: Time.current)
    second.update!(paused_at: Time.current)
    revision = work.reload.revision
    create(:message, account: account, conversation: conversation, content: 'New incoming message after pause')
    create(:message, :outgoing, account: account, conversation: conversation, content: 'New agent reply after pause')
    fresh = create(:conversation, account: account)
    create(:message, account: account, conversation: fresh, content: 'New conversation after pause')
    evaluate.call

    expect(work.reload.revision).to eq(revision)
    expect(ConversationMonitors::WorkItem.where(conversation: fresh)).not_to exist
    expect(monitor.evaluations.sole.status).to eq('matched')
    expect(second.evaluations.sole.status).to eq('unmatched')
    expect(WebMock).to have_requested(:post, endpoint).once
  end

  it 'excludes paused conditions while continuing other monitors on the same conversation' do
    monitor.update!(paused_at: Time.current)
    evaluate.call

    expect(WebMock).to have_requested(:post, endpoint).with { |request| JSON.parse(request.body)['questions'].keys == [second.id.to_s] }.once
    expect(monitor.evaluations).not_to exist
    expect(second.evaluations.sole.status).to eq('unmatched')
  end

  it 'discards a provider result if the monitor was paused during the request' do
    stub_request(:post, endpoint).to_return do
      monitor.update!(paused_at: Time.current)
      { status: 200, body: response_body.to_json }
    end
    evaluate.call

    expect(monitor.evaluations).not_to exist
    expect(second.evaluations.sole.status).to eq('unmatched')
  end

  it 'does not send a later batch for monitors paused during an earlier request' do
    monitors = create_list(:conversation_monitor, 19, account: account, created_at: 1.minute.ago)
    stub_request(:post, endpoint).to_return do |request|
      monitors.each { |entry| entry.update!(paused_at: Time.current) }
      values = JSON.parse(request.body)['questions'].keys.index_with { { type: 'noul', noul: 0.9 } }
      { status: 200, body: response_body.merge(answers: values).to_json }
    end
    evaluate.call

    expect(WebMock).to have_requested(:post, endpoint).once
    expect(ConversationMonitors::Evaluation.where(monitor: monitors)).not_to exist
  end
end
