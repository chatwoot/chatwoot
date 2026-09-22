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
  let(:endpoint) { ConversationMonitors::Configuration::ENDPOINT }

  before do
    create(:installation_config, name: 'CAPTAIN_OPENROUTER_API_KEY', value: 'test-key')
    account.enable_features!('reports', 'conversation_monitors')
    monitor
    second
    message
    ConversationMonitors::Scheduler.request(conversation, activity_at: message.created_at)
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

  it 'leaves invalid credentials visible without endlessly retrying' do
    stub_request(:post, endpoint).to_return(status: 401)
    evaluate.call

    expect(work.reload.due_at).to be_nil
    expect(monitor.evaluations.sole.error_code).to eq('credentials_invalid')
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
