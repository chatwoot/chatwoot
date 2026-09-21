require 'rails_helper'

RSpec.describe Copilot::V2::Runner do
  let(:account) { create(:account) }
  let(:user) { create(:user, account: account) }
  let(:thread) { CopilotThread.create!(account: account, user: user, engine: :v2, title: 'Test') }
  let(:message) { thread.copilot_messages.create!(message_type: :user, message: { content: 'Find conversations where customers reported slowness' }) }
  let(:service) { Copilot::V2::RunService.new(thread: thread, user: user) }
  let(:client) { instance_double(Copilot::V2::ChatService) }

  before do
    account.enable_features!('copilot_v2')
    allow(Copilot::V2::ChatService).to receive(:new).and_return(client)
  end

  def reply(content: nil, calls: [])
    RubyLLM::Message.new(role: :assistant, content: content || '', input_tokens: 20, output_tokens: 10,
                         tool_calls: calls.to_h { |id, name, args| [id, RubyLLM::ToolCall.new(id: id, name: name, arguments: args)] })
  end

  def selection_args
    { 'resource' => 'conversations', 'fields' => nil, 'filters' => [], 'order' => 'oldest', 'limit' => nil,
      'personal' => nil, 'mention_window' => nil }
  end

  def drive(run, limit: 30)
    limit.times do
      break unless %w[queued running].include?(run.reload.status)

      described_class.new(run).call
    end
    run.reload
  end

  it 'starts one durable run per triggering message and enforces one active run per thread' do
    run = service.start(message: message)
    expect(service.start(message: message).id).to eq(run.id)
    second = thread.copilot_messages.create!(message_type: :user, message: { content: 'Another request' })
    expect { service.start(message: second) }.to raise_error(Copilot::V2::RunService::ActiveRunConflict)
    expect(thread.copilot_runs.count).to eq(1)
  end

  it 'fences an expired worker and recovers queued and stranded claims' do
    run = service.start(message: message)
    old = run.claim!
    run.update!(lease_expires_at: 1.minute.ago)
    replacement = run.claim!
    expect(replacement).to be > old
    expect { run.fenced!(old) { run.update!(reason: 'stale') } }.to raise_error(described_class::StaleClaim)
    run.update!(lease_expires_at: 1.minute.ago)
    expect { Copilot::V2::RecoveryJob.perform_now }.to have_enqueued_job(Copilot::V2::RunJob).with(run.id)
  end

  it 'runs natural language through native operation IDs, captured evidence, validated analysis and saved results' do # rubocop:disable RSpec/MultipleExpectations
    allow(ChatwootApp).to receive(:chatwoot_cloud?).and_return(true)
    inbox = create(:inbox, account: account)
    create(:inbox_member, inbox: inbox, user: user)
    conversation = create(:conversation, account: account, inbox: inbox)
    evidence = create(:message, :incoming, account: account, inbox: inbox, conversation: conversation, content: 'The app is very slow')
    run = service.start(message: message)
    selection_ref = "run#{run.id}:operation1"
    evidence_ref = "run#{run.id}:operation2"
    result_ref = "run#{run.id}:operation3"
    responses = [reply(calls: [['catalog', 'resource_catalog', {}], ['select', 'select_resources', selection_args]]),
                 reply(calls: [['read', 'read_related', { 'selection_ref' => selection_ref, 'relationship' => 'messages', 'fields' => nil,
                                                          'filters' => [], 'window' => nil, 'customer_only' => false }]]),
                 reply(calls: [['analyze', 'analyze_records', { 'evidence_ref' => evidence_ref, 'mode' => 'classify',
                                                                'instruction' => 'Match direct reports of app slowness', 'fields' => [] }]]),
                 reply(calls: [['show', 'show_results', { 'result_ref' => result_ref, 'supersedes_ref' => nil }]]),
                 reply(content: { 'status' => 'completed', 'answer' => 'One conversation reports app slowness.' }.to_json)]
    allow(client).to receive(:coordinate) { responses.shift || raise('Unexpected coordinator call') }
    finding = { record_id: conversation.id, decision: 'match', reason: 'Direct complaint', values: {},
                citations: [{ record_id: evidence.id, part_id: "message:#{evidence.id}:body" }] }
    allow(client).to receive(:analyze).and_return(reply(content: { results: [finding] }.to_json))
    expect(drive(run).status).to eq('completed')
    summary = run.result_summary.fetch('results').first
    expect(summary.slice('selected_count', 'resolved_count', 'match_count', 'uncertain_count')).to eq(
      'selected_count' => 1, 'resolved_count' => 1, 'match_count' => 1, 'uncertain_count' => 0
    )
    expect(run.response_message.copilot_run).to eq(run)
    expect(run.budget['logical_model_calls']).to eq(6)
    calls = run.checkpoint['transcript'].flat_map { |entry| Array(entry['tool_calls']).pluck('id') }
    results = run.checkpoint['transcript'].filter_map { |entry| entry['tool_call_id'] }
    expect(results).to match_array(calls)
    expect(results.uniq).to eq(results)
    described_class.new(run).call
    expect(run.reload.budget['logical_model_calls']).to eq(6)
    expect(client).to have_received(:analyze).once
    expect(account.reload.custom_attributes['captain_responses_usage']).to eq(1)
  end

  it 'keeps consumed budget when explicitly resumed and pauses disabled execution' do
    run = service.start(message: message)
    run.update!(budget: { 'logical_model_calls' => Copilot::V2::Limits::MODEL_CALLS })
    described_class.new(run).call
    expect(run.reload.reason).to eq('model_call_budget')
    service.resume(run: run)
    expect(run.reload.budget['logical_model_calls']).to eq(Copilot::V2::Limits::MODEL_CALLS)
    account.disable_features!('copilot_v2')
    described_class.new(run).call
    expect(run.reload.reason).to eq('feature_disabled')
    expect(run.structured_result['usage']['logical_model_calls']).to eq(Copilot::V2::Limits::MODEL_CALLS)
  end

  it 'continues a clarification on the same run and does not charge the question' do
    run = service.start(message: message)
    allow(client).to receive(:coordinate).and_return(reply(content: { status: 'needs_clarification',
                                                                      answer: 'Do you mean app or API slowness?' }.to_json))
    described_class.new(run).call
    expect(run.reload.status).to eq('needs_clarification')
    expect(run.charged_at).to be_nil
    followup = thread.copilot_messages.create!(message_type: :user, message: { content: 'App slowness' })
    expect(service.start(message: followup).id).to eq(run.id)
    expect(service.start(message: followup).id).to eq(run.id)
    expect(run.reload.checkpoint['transcript'].last['content']).to eq('App slowness')
    question_id = thread.copilot_messages.assistant.last.id
    run.update!(budget: run.budget.merge('logical_model_calls' => Copilot::V2::Limits::MODEL_CALLS))
    described_class.new(run).call
    expect(run.reload.response_message_id).not_to eq(question_id)
    expect(run.response_message.message['content']).to include('incomplete')
  end

  it 'deletes run and cyclic outcome associations when their thread is removed' do
    run = service.start(message: message)
    answer = thread.copilot_messages.create!(message_type: :assistant, copilot_run: run, message: { content: 'Saved answer' })
    run.update!(response_message: answer)
    expect { thread.destroy! }.not_to raise_error
    expect(CopilotRun.exists?(run.id)).to be(false)
    expect(answer.reload.copilot_run_id).to be_nil
  end

  it 'enforces account concurrency across threads and rejects exhausted shared response credits' do
    stub_const('Copilot::V2::Limits::ACCOUNT_CONCURRENCY', 1)
    first = service.start(message: message)
    expect(first.claim!).to be_present
    other = CopilotThread.create!(account: account, user: user, engine: :v2, title: 'Other')
    trigger = other.copilot_messages.create!(message_type: :user, message: { content: 'Hello' })
    second = Copilot::V2::RunService.new(thread: other, user: user).start(message: trigger)
    expect(second.claim!).to be_nil
    first.update!(status: 'completed', lease_expires_at: nil)
    account.update!(limits: { captain_responses: 0 })
    described_class.new(second).call
    expect(second.reload.reason).to eq('response_credits_unavailable')
    expect(second.budget).to eq({})
  end

  it 'returns denied capabilities as tool results while rejecting metadata for message analysis before provider calls' do
    run = service.start(message: message)
    run.update!(checkpoint: { 'transcript' => [{ 'role' => 'user', 'content' => 'Read contacts' }], 'operations' => [
                  { 'id' => 'denied', 'name' => 'select_resources',
                    'arguments' => selection_args.merge('resource' => 'contacts'), 'state' => 'pending' }
                ] })
    runner = described_class.new(run)
    allow(runner.resources).to receive(:select).and_raise(Pundit::NotAuthorizedError)
    runner.call
    result = run.reload.checkpoint['operations'].first.fetch('result')
    expect(result['code']).to eq('access_denied')
    expect(run.status).to eq('queued')
    expect(run.budget).to eq({})
    expect { Copilot::V2::Resources.require_message_evidence!('reference_type' => 'selection', 'resource' => 'conversations') }
      .to raise_error(ArgumentError, /Message evidence/)
  end
end
