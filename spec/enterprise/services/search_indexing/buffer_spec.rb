require 'rails_helper'

RSpec.describe SearchIndexing::Buffer do
  include_context 'with search indexing Redis'

  let(:buffer) { described_class.new(entity: 'conversations', account_id: 1) }

  before do
    allow(SearchIndexing::Registry).to receive(:fetch).with('conversations').and_return(SearchIndexing::Document)
  end

  it 'coalesces IDs and retains a change arriving during a claimed write' do
    buffer.enqueue([1, 1, 2])
    expect(buffer.statistics[:pending]).to eq(2)
    batch = buffer.claim
    buffer.enqueue([1])
    outcomes = batch[:revisions].map { |id, revision| { id: id, revision: revision, state: 'success' } }
    buffer.acknowledge(batch, outcomes)
    expect(buffer.statistics[:pending]).to eq(1)
    expect(buffer.claim[:revisions].keys).to eq(['1'])
  end

  it 'recovers abandoned claims and rejects acknowledgements from expired owners' do
    buffer.enqueue([1])
    abandoned = buffer.claim
    travel 121.seconds do
      recovered = buffer.claim
      expect(recovered[:version]).to be > abandoned[:version]
      buffer.acknowledge(abandoned, [{ id: '1', revision: abandoned[:revisions]['1'], state: 'success' }])
      expect(buffer.statistics[:pending]).to eq(1)
      buffer.acknowledge(recovered, [{ id: '1', revision: recovered[:revisions]['1'], state: 'success' }])
      expect(buffer.statistics[:pending]).to eq(0)
    end
  end

  it 'retains permanent item failures for explicit retry' do
    buffer.enqueue([1])
    batch = buffer.claim
    buffer.acknowledge(batch, [{ id: '1', revision: batch[:revisions]['1'], state: 'failed', error: 'mapping_exception' }])
    expect(buffer.statistics).to include(pending: 0, failed: 1)
    buffer.retry_failed
    expect(buffer.statistics).to include(pending: 1, failed: 0)
  end

  it 'invalidates old work after the sequence is lost' do
    buffer.enqueue([1])
    old_epoch = buffer.epoch
    indexing_redis.del(SearchIndexing::Store::SEQUENCE_KEY)
    expect(SearchIndexing::Store.epoch).not_to eq(old_epoch)
    expect { buffer.claim }.to(raise_error { |error| expect(error.class.name).to eq('SearchIndexing::StaleGenerationError') })
  end

  it 'lets later accounts progress while earlier streams retain a backlog' do
    stub_const('SearchIndexing::Store::DISPATCH_LIMIT', 2)
    buffers = (1..3).map { |id| described_class.new(entity: 'conversations', account_id: id) }
    buffers.each { |entry| entry.enqueue((1..501).to_a) }
    expect(SearchIndexing::Store.due_streams).to eq(buffers.first(2).map(&:stream))
    travel 1.second do
      buffers.first(2).each do |entry|
        batch = entry.claim
        entry.acknowledge(batch, batch[:revisions].map { |id, revision| { id: id, revision: revision, state: 'success' } })
      end
      buffers.last.enqueue([502])
      expect(SearchIndexing::Store.due_streams.first).to eq(buffers.last.stream)
    end
  end
end
