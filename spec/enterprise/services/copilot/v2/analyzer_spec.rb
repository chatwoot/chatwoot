require 'rails_helper'

RSpec.describe Copilot::V2::Analyzer do
  let(:account) { create(:account) }
  let(:user) { create(:user, account: account) }
  let(:thread) { CopilotThread.create!(account: account, user: user, engine: :v2, title: 'Analysis') }
  let(:message) { thread.copilot_messages.create!(message_type: :user, message: { content: 'Find complaints' }) }
  let(:run) { Copilot::V2::RunService.new(thread: thread, user: user).start(message: message) }
  let(:runner) { Copilot::V2::Runner.new(run) }
  let(:specification) { { 'mode' => 'classify', 'instruction' => 'Find app slowness complaints', 'fields' => [] } }
  let(:manifest) do
    { 'reference_type' => 'evidence', 'resource' => 'conversations', 'evidence_resource' => 'messages',
      'selected_ids' => [1, 2], 'selection' => { 'complete' => false }, 'items' => [] }
  end
  let(:client) { instance_double(Copilot::V2::ChatService) }

  before do
    account.enable_features!('copilot_v2')
    run.update!(datasets: { 'evidence' => manifest.except('items') })
    runner.instance_variable_set(:@generation, run.claim!)
    allow(runner.resources).to receive(:authorize_manifest!).and_return(true)
    allow(runner).to receive(:client).and_return(client)
    allow(client).to receive(:analyze)
  end

  def capture(id, text: 'The app is slow')
    value = { 'id' => id, 'identity' => { 'id' => id, 'contact_id' => 50 }, 'records' => [
      { 'id' => id * 10, 'parts' => [{ 'id' => "message:#{id * 10}:body", 'text' => text }], 'limitations' => [] }
    ] }
    run.copilot_run_items.create!(dataset_key: 'evidence', resource_type: 'conversations', resource_id: id.to_s,
                                  position: id, captured: value)
    manifest['items'] << value.merge('state' => 'captured')
  end

  def response(id, decision: 'match')
    row = { record_id: id, decision: decision, reason: 'Observed text', values: {},
            citations: [{ record_id: id * 10, part_id: "message:#{id * 10}:body" }] }
    RubyLLM::Message.new(role: :assistant, content: { results: [row] }.to_json, input_tokens: 10, output_tokens: 10)
  end

  it 'keeps oversized records unresolved, saves valid rows, and publishes exact partial coverage on exhaustion' do # rubocop:disable RSpec/MultipleExpectations
    capture(1)
    capture(2, text: 'x' * Copilot::V2::Limits::REQUEST_BYTES)
    allow(client).to receive(:analyze).and_return(response(1))
    analyzer = described_class.new(runner)
    analyzer.process('result', 'evidence', manifest, specification)
    receipt = analyzer.process('result', 'evidence', manifest, specification)
    expect(receipt['resolved_ids']).to eq([1])
    expect(receipt['unresolved_ids']).to eq([2])
    expect(receipt['selection_complete']).to be(false)
    expect(receipt['processing_complete']).to be(false)
    expect(run.copilot_run_items.find_by!(dataset_key: 'result', resource_id: '2').reason).to eq('evidence_too_large')
    runner.send(:pause, 'model_call_budget')
    expect(run.reload.result_summary['results'].first['rows'].first['record_id']).to eq(1)
    expect(run.response_message.message['content']).to include('incomplete')
    expect(client).to have_received(:analyze).once
  end

  it 'does not mark evidence supplied or consume an item retry when the provider budget rejects a call' do
    capture(1)
    run.update!(budget: { 'logical_model_calls' => Copilot::V2::Limits::MODEL_CALLS })
    expect { described_class.new(runner).process('result', 'evidence', manifest, specification) }.to raise_error(Copilot::V2::Runner::BudgetExceeded)
    item = run.copilot_run_items.find_by!(dataset_key: 'result')
    expect(item.attempts).to eq(0)
    expect(item.supplied).to be(false)
    expect(client).not_to have_received(:analyze)
  end

  it 'retains a lost in-flight attempt and exhausts malformed result retries without resetting them on replay' do
    capture(1)
    allow(client).to receive(:analyze).and_return(RubyLLM::Message.new(role: :assistant, content: '{}'))
    analyzer = described_class.new(runner)
    3.times { analyzer.process('result', 'evidence', manifest, specification) }
    item = run.copilot_run_items.find_by!(dataset_key: 'result')
    expect(item.state).to eq('unresolved')
    expect(item.attempts).to eq(2)
    expect(run.budget['logical_model_calls']).to eq(2)
    expect(client).to have_received(:analyze).twice
  end

  it 'counts distinct customers and keeps uncertain results separate from matches' do
    capture(1)
    capture(2)
    allow(client).to receive(:analyze).and_return(RubyLLM::Message.new(role: :assistant, content: {
      results: [JSON.parse(response(1).content)['results'][0], JSON.parse(response(2, decision: 'uncertain').content)['results'][0]]
    }.to_json))
    described_class.new(runner).process('result', 'evidence', manifest, specification)
    results = Copilot::V2::Results.new(run)
    expect(results.projection('result').slice('match_count', 'uncertain_count', 'resolved_count')).to eq(
      'match_count' => 1, 'uncertain_count' => 1, 'resolved_count' => 2
    )
    expect(results.aggregate('result', group_by: [], unit: 'customers')['denominator']).to eq(1)
  end

  it 'retains independent published analyses and replaces only an explicitly superseded result' do
    capture(1)
    manifest['selection']['complete'] = true
    run.update!(datasets: { 'evidence' => manifest.except('items') })
    allow(client).to receive(:analyze).and_return(response(1))
    allow(runner.resources).to receive(:freshness).and_return({})
    analyzer = described_class.new(runner)
    analyzer.process('first', 'evidence', manifest, specification)
    analyzer.process('second', 'evidence', manifest, specification.merge('instruction' => 'Find priority'))
    run.copilot_run_items.find_by!(dataset_key: 'first').update!(state: 'unresolved', reason: 'old_failure')
    operations = Copilot::V2::Operations.new(runner)
    operations.send(:publish, 'first')
    operations.send(:publish, 'second')
    expect(run.checkpoint['published_refs']).to eq(%w[first second])
    operations.send(:publish, 'second', supersedes_ref: 'first')
    expect(run.checkpoint['published_refs']).to eq(['second'])
    runner.send(:finalize, { 'status' => 'completed', 'answer' => 'Saved current findings.' },
                { 'role' => 'assistant', 'content' => 'Saved current findings.' })
    expect(run.status).to eq('completed')
    expect(run.result_summary['results'].pluck('reference')).to eq(['second'])
  end

  it 'rejects an oversized dynamic schema before creating work or marking evidence supplied' do
    capture(1)
    fields = [{ 'name' => 'value', 'type' => 'string', 'values' => ['x' * Copilot::V2::Limits::REQUEST_BYTES] }]
    expect do
      described_class.new(runner).process('result', 'evidence', manifest, specification.merge('fields' => fields))
    end.to raise_error(ArgumentError, /specification exceeds/)
    expect(run.copilot_run_items.where(dataset_key: 'result')).to be_empty
    expect(run.budget).to eq({})
  end

  it 'resumes an interrupted batch from the same captured items without repeating completed work' do
    stub_const('Copilot::V2::Limits::BATCH_SIZE', 1)
    capture(1)
    capture(2)
    allow(client).to receive(:analyze).and_return(response(1), response(2))
    described_class.new(runner).process('result', 'evidence', manifest, specification)
    run.update!(lease_expires_at: 1.minute.ago)
    replacement = Copilot::V2::Runner.new(run.reload)
    replacement.instance_variable_set(:@generation, run.claim!)
    allow(replacement.resources).to receive(:authorize_manifest!).and_return(true)
    allow(replacement).to receive(:client).and_return(client)
    analyzer = described_class.new(replacement)
    analyzer.process('result', 'evidence', manifest, specification)
    receipt = analyzer.process('result', 'evidence', manifest, specification)
    expect(receipt['resolved_ids']).to eq([1, 2])
    expect(run.copilot_run_items.where(dataset_key: 'result').count).to eq(2)
    expect(run.copilot_run_items.where(dataset_key: 'result').pluck(:attempts)).to eq([1, 1])
    expect(client).to have_received(:analyze).twice
    expect(run.budget['logical_model_calls']).to eq(2)
  end

  it 'keeps an inaccessible captured item unresolved while processing the permitted subset' do
    capture(1)
    capture(2)
    allow(runner.resources).to receive(:authorize_manifest!).with(manifest, item_ids: [2]).and_raise(Pundit::NotAuthorizedError)
    allow(client).to receive(:analyze).and_return(response(1))
    analyzer = described_class.new(runner)
    analyzer.process('result', 'evidence', manifest, specification)
    result = analyzer.process('result', 'evidence', manifest, specification)
    expect(result['resolved_ids']).to eq([1])
    expect(result['unresolved']).to eq([{ 'id' => 2, 'reason' => 'record_unavailable' }])
  end
end
