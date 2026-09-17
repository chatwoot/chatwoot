require 'rails_helper'

RSpec.describe Captain::Apropos::Runtime do
  let(:account) { create(:account) }
  let(:user) { create(:user, account: account, role: :administrator) }
  let(:runtime) { described_class.new(account: account, user: user) }

  before { account.enable_features!('captain_integration') }

  it 'runs the new WootQL through Scheme and feeds real lists to callbacks' do
    contact = create(:contact, account: account, name: 'A customer')
    result = runtime.execute('(define page (query-run "contacts | return id, name | sort id"))
      (query-map (lambda (rows) (map (lambda (row) (get row "name")) rows)) page)')
    expect(result).to include('kind' => 'processing_result', 'processed_item_count' => 1, 'processed_page_count' => 1, 'query_exhausted' => true)
    reference = result.fetch('results').sole.fetch('ref')
    expect(runtime.execute("(recall #{reference.to_json})")).to eq([contact.name])
    expect(result).not_to have_key('processed_rows')
  end

  it 'preserves state and saved functions across turns without replaying actions' do
    runtime.execute('(define n 7) (save-function "plus-one" "Increment a number" (quote (lambda (x) (+ x 1))))')
    restored = described_class.new(account: account, user: user, state: JSON.parse(JSON.generate(runtime.state)))
    expect(restored.execute('(plus-one n)')).to eq(8)
    expect(restored.catalog.describe('member')[:description]).to include('Scheme procedure')
    expect(restored.catalog.describe('plus-one')[:binding]).to eq(type: 'closure', source: '(lambda (x) (+ x 1))')
  end

  it 'passes Scheme data and schemas to reasoning without sending persistence envelopes' do
    expect(runtime).to receive(:ask).with('Classify', input: [{ 'id' => 1 }], schema: { 'category' => 'string' }, tools: false)
                                    .and_return('category' => 'billing')
    result = runtime.execute('(reason (list (hash "id" 1)) "Classify" (hash "category" "string"))')
    expect(result).to eq('category' => 'billing')
  end

  it 'retains displayed table rows and action receipts when a later expression fails' do
    runtime.scheme.register('test-action') do
      runtime.record('action', { 'operation' => 'test', 'status' => 'completed' })
      true
    end
    expect do
      runtime.execute('(test-action) (show-table (list (hash "id" 1)) (list "id")) (car 9)')
    end.to raise_error(Scheme::Error)
    expect(runtime.receipts.size).to eq(1)
    expect(runtime.events.count { |event| event['kind'] == 'table' }).to eq(1)
    expect(runtime.execution_failure[:context][:receipt_count]).to eq(1)
    expect { JSON.generate(runtime.state) }.not_to raise_error
  end

  it 'returns record-page metadata and keeps label membership scoped to the account' do
    ours = create(:conversation, account: account)
    ours.update!(label_list: ['refund'])
    other = create(:conversation)
    other.update!(label_list: ['refund'])
    result = runtime.execute('(query-run "conversations | where labels contains \\"refund\\" | return id, labels")')
    expect(result.fetch('items')).to eq([{ 'id' => ours.id, 'labels' => ['refund'] }])
    records = runtime.execute('(search "contacts")')
    expect(records).to include('kind' => 'record_page', 'item_count' => 1, 'has_more' => false)
  end

  it 'keeps previews distinguishable from full values and query pages' do
    rows = Array.new(100) { { 'content' => 'x' * 300 } }
    preview = runtime.model_value(rows)
    expect(preview).to include('kind' => 'preview', 'complete' => false, 'value_info' => { 'type' => 'list', 'item_count' => 100 })
    expect(runtime.execute("(length (recall #{preview.fetch('ref').to_json}))")).to eq(100)
    expect { runtime.query_next(preview) }.to raise_error(Captain::Apropos::Error, /Expected a query page/)
  end

  it 'makes a previewed resource catalog readable through recall before and after restoring state' do
    catalog = runtime.catalog.describe('resources')
    preview = runtime.model_value(catalog, limit: 100)
    expect(preview).to include('kind' => 'preview', 'complete' => false)

    source = "(get (get (get (recall #{preview.fetch('ref').to_json}) \"members\") \"conversations\") \"fields\")"
    expect(runtime.execute(source)).to include('id', 'custom_attributes')

    restored = described_class.new(account: account, user: user, state: JSON.parse(JSON.generate(runtime.state)))
    expect(restored.execute(source)).to eq(runtime.execute(source))
  end

  it 'retains completed callback results after a later page fails without retrying callbacks' do
    prepared = instance_double(Wootql::PreparedQuery)
    query = instance_double(Wootql::Query, prepare: prepared)
    runtime.instance_variable_set(:@query, query)
    allow(prepared).to receive(:page).with(0).and_return('items' => [{ 'id' => 1 }], 'next_offset' => 200)
    allow(prepared).to receive(:page).with(200).and_return('items' => [{ 'id' => 2 }], 'next_offset' => false)
    expect do
      runtime.execute('(define calls 0) (define page (query-run "contacts"))
        (query-map (lambda (rows) (set! calls (+ calls 1)) (if (= calls 2) (error "stop") rows)) page)')
    end.to raise_error(StandardError, /Progress is saved/)
    progress = runtime.scheme.workspace.values.map { |value| Captain::Apropos::SchemeValues.describe_value(value) }
                      .find { |value| value.is_a?(Hash) && value['kind'] == 'processing_result' }
    expect(progress).to include('status' => 'failed', 'processed_item_count' => 1, 'page_processed' => false, 'query_exhausted' => false)
    expect(progress.fetch('results').size).to eq(1)
    expect(runtime.execute('calls')).to eq(2)
    expect(query).to have_received(:prepare).once
  end

  it 'keeps query handles turn-local and never silently rebuilds a saved query page' do
    runtime.execute('(define page (query-run "contacts | take 1"))')
    state = JSON.parse(JSON.generate(runtime.state))
    restored = described_class.new(account: account, user: user, state: state)
    # A final page remains exhausted; a live continuation cannot cross turns.
    expect(restored.execute('(query-next page)')).to be(false)
    expect { restored.query_next('kind' => 'page', 'items' => [], 'has_more' => true, 'query_ref' => 'unknown', 'next_offset' => 200) }
      .to raise_error(Captain::Apropos::Error, /not active in this turn/)
  end
end
