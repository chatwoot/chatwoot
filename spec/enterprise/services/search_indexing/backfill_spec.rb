require 'rails_helper'

RSpec.describe SearchIndexing::Backfill do
  include_context 'with search indexing Redis'

  let(:account) { create(:account) }
  let(:state) { described_class.start(account: account, entity: 'conversations') }
  let(:client) { instance_double(OpenSearch::Client) }
  let(:indices) { instance_double(OpenSearch::API::Indices::IndicesClient) }

  before do
    allow(ChatwootApp).to receive_messages(advanced_search_allowed?: true, chatwoot_cloud?: false)
    account.enable_features!('conversation_search_indexing')
    allow(Searchkick).to receive(:client).and_return(client)
    allow(client).to receive(:indices).and_return(indices)
    allow(indices).to receive(:exists?).and_return(true)
    allow(indices).to receive(:refresh).and_return('_shards' => { 'failed' => 0 })
  end

  it 'rejects contact backfills' do
    expect { described_class.start(account: account, entity: 'contacts') }.to raise_error(KeyError)
    expect(SearchIndexing::IndexState.count).to eq(0)
  end

  it 'queues a source page and advances the durable cursor' do
    conversation = create(:conversation, account: account)
    described_class.new(state).perform
    expect(state.reload).to have_attributes(cursor: conversation.id, scanned_count: 1, status: 'running')
    expect(state.buffer.statistics[:pending]).to eq(1)
  end

  it 'does not advance verification after a partial response' do
    state.update!(phase: 'verify_index')
    allow(client).to receive(:search).and_return('timed_out' => false, '_shards' => { 'failed' => 1 })
    expect { described_class.new(state).perform }.to raise_error(Searchkick::Error, /incomplete response/)
    expect(state.reload).to have_attributes(cursor: 0, phase: 'verify_index')
  end

  it 'rejects readiness and stops backfills after a permanent write failure' do
    state.update!(status: 'ready', ready_at: Time.current)
    state.buffer.enqueue([123])
    batch = state.buffer.claim
    state.buffer.acknowledge(batch, [{ id: '123', revision: batch[:revisions]['123'], state: 'failed' }])
    expect(state).not_to be_readable
    described_class.new(state).perform
    expect(state.reload).to have_attributes(status: 'failed', ready_at: nil, last_error: 'bulk_item_failure')
  end

  it 'creates purge work for a used stream without an earlier backfill' do
    SearchIndexing::Buffer.new(entity: 'conversations', account_id: account.id).enqueue([123])
    expect(SearchIndexing::IndexState.count).to eq(0)
    expect { account.send(:purge_search_documents) }.to have_enqueued_job(SearchIndexing::BackfillJob)
    expect(SearchIndexing::IndexState.sole).to have_attributes(account_id: account.id, phase: 'verify_index', status: 'running')
  end

  it 'does not create purge work for accounts that never indexed' do
    expect { account.send(:purge_search_documents) }.not_to change(SearchIndexing::IndexState, :count)
  end

  it 'moves purge work to the current generation and invalidates the old job token' do
    token = state.run_token
    state.update!(epoch: 'old', schema_version: 1, ready_at: Time.current, cursor: 99)
    account.send(:purge_search_documents)
    expect(state.reload).to have_attributes(epoch: SearchIndexing::Store.epoch, schema_version: 2, cursor: 0, ready_at: nil)
    expect(state.run_token).not_to eq(token)
  end

  it 'continues a deleted-account purge even when earlier writes failed' do
    state.update!(phase: 'verify_index')
    allow(state).to receive(:account).and_return(nil)
    state.buffer.enqueue([123])
    batch = state.buffer.claim
    state.buffer.acknowledge(batch, [{ id: '123', revision: batch[:revisions]['123'], state: 'failed' }])
    allow(client).to receive(:search).and_return('_shards' => { 'failed' => 0 }, 'hits' => { 'hits' => [] })
    described_class.new(state).perform
    expect(state.reload.phase).to eq('drain')
    described_class.new(state).perform
    expect(state.reload.status).to eq('purged')
  end

  it 'ignores stale jobs after pausing and resumes with a new token' do
    token = state.run_token
    state.pause!
    SearchIndexing::BackfillJob.perform_now(state.id, token)
    expect(state.reload).to have_attributes(status: 'paused', cursor: 0)
    clear_enqueued_jobs
    state.resume!
    expect(SearchIndexing::BackfillJob).to have_been_enqueued.with(state.id, state.run_token)
    expect(state.run_token).not_to eq(token)
  end
end
